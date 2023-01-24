import Env
import Models
import Network
import Status
import SwiftUI

@MainActor
class AccountDetailViewModel: ObservableObject, StatusesFetcher {
  let accountId: String
  var client: Client?
  var isCurrentUser: Bool = false

  enum AccountState {
    case loading, data(account: Account), error(error: Error)
  }

  enum Tab: Int {
    case statuses, favorites, bookmarks, followedTags, postsAndReplies, media, lists

    static var currentAccountTabs: [Tab] {
      [.statuses, .favorites, .bookmarks, .followedTags, .lists]
    }

    static var accountTabs: [Tab] {
      [.statuses, .postsAndReplies, .media]
    }

    var iconName: String {
      switch self {
      case .statuses: return "bubble.right"
      case .favorites: return "star"
      case .bookmarks: return "bookmark"
      case .followedTags: return "tag"
      case .postsAndReplies: return "bubble.left.and.bubble.right"
      case .media: return "photo.on.rectangle.angled"
      case .lists: return "list.bullet"
      }
    }
  }

  enum TabState {
    case followedTags
    case statuses(statusesState: StatusesState)
    case lists
  }

  @Published var accountState: AccountState = .loading
  @Published var tabState: TabState = .statuses(statusesState: .loading) {
    didSet {
      /// Forward viewModel tabState related to statusesState to statusesState property
      /// for `StatusesFetcher` conformance as we wrap StatusesState in TabState
      switch tabState {
      case let .statuses(statusesState):
        self.statusesState = statusesState
      default:
        break
      }
    }
  }

  @Published var statusesState: StatusesState = .loading

  @Published var relationship: Relationship?
  @Published var pinned: [Status] = []
  @Published var favorites: [Status] = []
  @Published var bookmarks: [Status] = []
  private var favoritesNextPage: LinkHandler?
  private var bookmarksNextPage: LinkHandler?
  @Published var featuredTags: [FeaturedTag] = []
  @Published var fields: [Account.Field] = []
  @Published var familiarFollowers: [Account] = []
  @Published var selectedTab = Tab.statuses {
    didSet {
      switch selectedTab {
      case .statuses, .postsAndReplies, .media:
        tabTask?.cancel()
        tabTask = Task {
          await fetchStatuses()
        }
      default:
        reloadTabState()
      }
    }
  }

  private(set) var account: Account?
  private var tabTask: Task<Void, Never>?

  private(set) var statuses: [Status] = []

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
    if client.isAuth && !isCurrentUser {
      async let relationships: [Relationship] = client.get(endpoint: Accounts.relationships(ids: [accountId]))
      return try await .init(account: account,
                             featuredTags: featuredTags,
                             relationships: relationships)
    }
    return try await .init(account: account,
                           featuredTags: featuredTags,
                           relationships: [])
  }

  func fetchFamilliarFollowers() async {
    let familiarFollowers: [FamiliarAccounts]? = try? await client?.get(endpoint: Accounts.familiarFollowers(withAccount: accountId))
    self.familiarFollowers = familiarFollowers?.first?.accounts ?? []
  }

  func fetchStatuses() async {
    guard let client else { return }
    do {
      tabState = .statuses(statusesState: .loading)
      statuses =
        try await client.get(endpoint: Accounts.statuses(id: accountId,
                                                         sinceId: nil,
                                                         tag: nil,
                                                         onlyMedia: selectedTab == .media ? true : nil,
                                                         excludeReplies: selectedTab == .statuses && !isCurrentUser ? true : nil,
                                                         pinned: nil))
      if selectedTab == .statuses {
        pinned =
          try await client.get(endpoint: Accounts.statuses(id: accountId,
                                                           sinceId: nil,
                                                           tag: nil,
                                                           onlyMedia: nil,
                                                           excludeReplies: nil,
                                                           pinned: true))
      }
      if isCurrentUser {
        (favorites, favoritesNextPage) = try await client.getWithLink(endpoint: Accounts.favorites(sinceId: nil))
        (bookmarks, bookmarksNextPage) = try await client.getWithLink(endpoint: Accounts.bookmarks(sinceId: nil))
      }
      reloadTabState()
    } catch {
      tabState = .statuses(statusesState: .error(error: error))
    }
  }

  func fetchNextPage() async {
    guard let client else { return }
    do {
      switch selectedTab {
      case .statuses, .postsAndReplies, .media:
        guard let lastId = statuses.last?.id else { return }
        tabState = .statuses(statusesState: .display(statuses: statuses, nextPageState: .loadingNextPage))
        let newStatuses: [Status] =
          try await client.get(endpoint: Accounts.statuses(id: accountId,
                                                           sinceId: lastId,
                                                           tag: nil,
                                                           onlyMedia: selectedTab == .media ? true : nil,
                                                           excludeReplies: selectedTab == .statuses && !isCurrentUser ? true : nil,
                                                           pinned: nil))
        statuses.append(contentsOf: newStatuses)
        tabState = .statuses(statusesState: .display(statuses: statuses,
                                                     nextPageState: newStatuses.count < 20 ? .none : .hasNextPage))
      case .favorites:
        guard let nextPageId = favoritesNextPage?.maxId else { return }
        let newFavorites: [Status]
        (newFavorites, favoritesNextPage) = try await client.getWithLink(endpoint: Accounts.favorites(sinceId: nextPageId))
        favorites.append(contentsOf: newFavorites)
        tabState = .statuses(statusesState: .display(statuses: favorites, nextPageState: .hasNextPage))
      case .bookmarks:
        guard let nextPageId = bookmarksNextPage?.maxId else { return }
        let newBookmarks: [Status]
        (newBookmarks, bookmarksNextPage) = try await client.getWithLink(endpoint: Accounts.bookmarks(sinceId: nextPageId))
        bookmarks.append(contentsOf: newBookmarks)
        tabState = .statuses(statusesState: .display(statuses: bookmarks, nextPageState: .hasNextPage))
      case .followedTags, .lists:
        break
      }
    } catch {
      tabState = .statuses(statusesState: .error(error: error))
    }
  }

  private func reloadTabState() {
    switch selectedTab {
    case .statuses, .postsAndReplies, .media:
      tabState = .statuses(statusesState: .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage))
    case .favorites:
      tabState = .statuses(statusesState: .display(statuses: favorites,
                                                   nextPageState: favoritesNextPage != nil ? .hasNextPage : .none))
    case .bookmarks:
      tabState = .statuses(statusesState: .display(statuses: bookmarks,
                                                   nextPageState: bookmarksNextPage != nil ? .hasNextPage : .none))
    case .followedTags:
      tabState = .followedTags
    case .lists:
      tabState = .lists
    }
  }

  func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    if let event = event as? StreamEventUpdate {
      if event.status.account.id == currentAccount.account?.id {
        statuses.insert(event.status, at: 0)
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
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
}
