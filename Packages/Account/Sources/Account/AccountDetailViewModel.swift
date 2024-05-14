import Env
import Models
import Network
import Observation
import StatusKit
import SwiftUI

@MainActor
@Observable class AccountDetailViewModel: StatusesFetcher {
  let accountId: String
  var client: Client?
  var isCurrentUser: Bool = false

  enum AccountState {
    case loading, data(account: Account), error(error: Error)
  }

  enum Tab: Int {
    case statuses, favorites, bookmarks, replies, boosts, media

    static var currentAccountTabs: [Tab] {
      [.statuses, .replies, .boosts, .favorites, .bookmarks]
    }

    static var accountTabs: [Tab] {
      [.statuses, .replies, .boosts, .media]
    }

    var iconName: String {
      switch self {
      case .statuses: "bubble.right"
      case .favorites: "star"
      case .bookmarks: "bookmark"
      case .replies: "bubble.left.and.bubble.right"
      case .boosts: ""
      case .media: "photo.on.rectangle.angled"
      }
    }

    var accessibilityLabel: LocalizedStringKey {
      switch self {
      case .statuses: "accessibility.tabs.profile.picker.statuses"
      case .favorites: "accessibility.tabs.profile.picker.favorites"
      case .bookmarks: "accessibility.tabs.profile.picker.bookmarks"
      case .replies: "accessibility.tabs.profile.picker.posts-and-replies"
      case .boosts: "accessibility.tabs.profile.picker.boosts"
      case .media: "accessibility.tabs.profile.picker.media"
      }
    }
  }

  var accountState: AccountState = .loading
  var statusesState: StatusesState = .loading

  var relationship: Relationship?
  var pinned: [Status] = []
  var favorites: [Status] = []
  var bookmarks: [Status] = []
  private var favoritesNextPage: LinkHandler?
  private var bookmarksNextPage: LinkHandler?
  var featuredTags: [FeaturedTag] = []
  var fields: [Account.Field] = []
  var familiarFollowers: [Account] = []
  var selectedTab = Tab.statuses {
    didSet {
      switch selectedTab {
      case .statuses, .replies, .boosts, .media:
        tabTask?.cancel()
        tabTask = Task {
          await fetchNewestStatuses(pullToRefresh: false)
        }
      default:
        reloadTabState()
      }
    }
  }

  var scrollToTopVisible: Bool = false

  var translation: Translation?
  var isLoadingTranslation = false

  private(set) var account: Account?
  private var tabTask: Task<Void, Never>?

  private(set) var statuses: [Status] = []

  var boosts: [Status] = []

  /// When coming from a URL like a mention tap in a status.
  init(accountId: String) {
    self.accountId = accountId
    isCurrentUser = false
  }

  /// When the account is already fetched by the parent caller.
  init(account: Account) {
    accountId = account.id
    self.account = account
    accountState = .data(account: account)
  }

  struct AccountData {
    let account: Account
    let featuredTags: [FeaturedTag]
    let relationships: [Relationship]
  }

  func fetchAccount() async {
    guard let client else { return }
    do {
      let data = try await fetchAccountData(accountId: accountId, client: client)
      accountState = .data(account: data.account)

      account = data.account
      fields = data.account.fields
      featuredTags = data.featuredTags
      featuredTags.sort { $0.statusesCountInt > $1.statusesCountInt }
      relationship = data.relationships.first
    } catch {
      if let account {
        accountState = .data(account: account)
      } else {
        accountState = .error(error: error)
      }
    }
  }

  private func fetchAccountData(accountId: String, client: Client) async throws -> AccountData {
    async let account: Account = client.get(endpoint: Accounts.accounts(id: accountId))
    async let featuredTags: [FeaturedTag] = client.get(endpoint: Accounts.featuredTags(id: accountId))
    if client.isAuth, !isCurrentUser {
      async let relationships: [Relationship] = client.get(endpoint: Accounts.relationships(ids: [accountId]))
      do {
        return try await .init(account: account,
                               featuredTags: featuredTags,
                               relationships: relationships)
      } catch {
        return try await .init(account: account,
                               featuredTags: [],
                               relationships: relationships)
      }
    }
    return try await .init(account: account,
                           featuredTags: featuredTags,
                           relationships: [])
  }

  func fetchFamilliarFollowers() async {
    let familiarFollowers: [FamiliarAccounts]? = try? await client?.get(endpoint: Accounts.familiarFollowers(withAccount: accountId))
    self.familiarFollowers = familiarFollowers?.first?.accounts ?? []
  }

  func fetchNewestStatuses(pullToRefresh _: Bool) async {
    guard let client else { return }
    do {
      statusesState = .loading
      boosts = []
      statuses =
        try await client.get(endpoint: Accounts.statuses(id: accountId,
                                                         sinceId: nil,
                                                         tag: nil,
                                                         onlyMedia: selectedTab == .media,
                                                         excludeReplies: selectedTab != .replies,
                                                         excludeReblogs: selectedTab != .boosts,
                                                         pinned: nil))
      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)
      if selectedTab == .boosts {
        boosts = statuses.filter { $0.reblog != nil }
      }
      if selectedTab == .statuses {
        pinned =
          try await client.get(endpoint: Accounts.statuses(id: accountId,
                                                           sinceId: nil,
                                                           tag: nil,
                                                           onlyMedia: false,
                                                           excludeReplies: false,
                                                           excludeReblogs: false,
                                                           pinned: true))
        StatusDataControllerProvider.shared.updateDataControllers(for: pinned, client: client)
      }
      if isCurrentUser {
        (favorites, favoritesNextPage) = try await client.getWithLink(endpoint: Accounts.favorites(sinceId: nil))
        (bookmarks, bookmarksNextPage) = try await client.getWithLink(endpoint: Accounts.bookmarks(sinceId: nil))
        StatusDataControllerProvider.shared.updateDataControllers(for: favorites, client: client)
        StatusDataControllerProvider.shared.updateDataControllers(for: bookmarks, client: client)
      }
      reloadTabState()
    } catch {
      statusesState = .error(error: error)
    }
  }

  func fetchNextPage() async throws {
    guard let client else { return }
    switch selectedTab {
    case .statuses, .replies, .boosts, .media:
      guard let lastId = statuses.last?.id else { return }
      let newStatuses: [Status] =
        try await client.get(endpoint: Accounts.statuses(id: accountId,
                                                         sinceId: lastId,
                                                         tag: nil,
                                                         onlyMedia: selectedTab == .media,
                                                         excludeReplies: selectedTab != .replies,
                                                         excludeReblogs: selectedTab != .boosts,
                                                         pinned: nil))
      statuses.append(contentsOf: newStatuses)
      if selectedTab == .boosts {
        let newBoosts = statuses.filter { $0.reblog != nil }
        boosts.append(contentsOf: newBoosts)
      }
      StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)
      if selectedTab == .boosts {
        statusesState = .display(statuses: boosts,
                                 nextPageState: newStatuses.count < 20 ? .none : .hasNextPage)
      } else {
        statusesState = .display(statuses: statuses,
                                 nextPageState: newStatuses.count < 20 ? .none : .hasNextPage)
      }
    case .favorites:
      guard let nextPageId = favoritesNextPage?.maxId else { return }
      let newFavorites: [Status]
      (newFavorites, favoritesNextPage) = try await client.getWithLink(endpoint: Accounts.favorites(sinceId: nextPageId))
      favorites.append(contentsOf: newFavorites)
      StatusDataControllerProvider.shared.updateDataControllers(for: newFavorites, client: client)
      statusesState = .display(statuses: favorites, nextPageState: .hasNextPage)
    case .bookmarks:
      guard let nextPageId = bookmarksNextPage?.maxId else { return }
      let newBookmarks: [Status]
      (newBookmarks, bookmarksNextPage) = try await client.getWithLink(endpoint: Accounts.bookmarks(sinceId: nextPageId))
      StatusDataControllerProvider.shared.updateDataControllers(for: newBookmarks, client: client)
      bookmarks.append(contentsOf: newBookmarks)
      statusesState = .display(statuses: bookmarks, nextPageState: .hasNextPage)
    }
  }

  private func reloadTabState() {
    switch selectedTab {
    case .statuses, .replies, .media:
      statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
    case .boosts:
      statusesState = .display(statuses: boosts, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
    case .favorites:
      statusesState = .display(statuses: favorites,
                               nextPageState: favoritesNextPage != nil ? .hasNextPage : .none)
    case .bookmarks:
      statusesState = .display(statuses: bookmarks,
                               nextPageState: bookmarksNextPage != nil ? .hasNextPage : .none)
    }
  }

  func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    if let event = event as? StreamEventUpdate {
      if event.status.account.id == currentAccount.account?.id {
        if (event.status.inReplyToId == nil && selectedTab == .statuses) ||
          (event.status.inReplyToId != nil && selectedTab == .replies)
        {
          statuses.insert(event.status, at: 0)
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        }
      }
    } else if let event = event as? StreamEventDelete {
      statuses.removeAll(where: { $0.id == event.status })
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } else if let event = event as? StreamEventStatusUpdate {
      if let originalIndex = statuses.firstIndex(where: { $0.id == event.status.id }) {
        statuses[originalIndex] = event.status
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    }
  }

  func statusDidAppear(status _: Models.Status) {}

  func statusDidDisappear(status _: Status) {}
}
