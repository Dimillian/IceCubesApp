import SwiftUI
import Network
import Models
import Status
import Env

@MainActor
class AccountDetailViewModel: ObservableObject, StatusesFetcher {
  let accountId: String
  var client: Client?
  var isCurrentUser: Bool = false
  
  enum AccountState {
    case loading, data(account: Account), error(error: Error)
  }
  
  enum Tab: Int {
    case statuses, favourites, followedTags, postsAndReplies, media, lists
    
    static var currentAccountTabs: [Tab] {
      [.statuses, .favourites, .followedTags, .lists]
    }
    
    static var accountTabs: [Tab] {
      [.statuses, .postsAndReplies, .media]
    }
    
    var title: String {
      switch self {
      case .statuses: return "Posts"
      case .favourites: return "Favorites"
      case .followedTags: return "Tags"
      case .postsAndReplies: return "Posts & Replies"
      case .media: return "Media"
      case .lists: return "Lists"
      }
    }
  }
  
  enum TabState {
    case followedTags(tags: [Tag])
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
  
  @Published var relationship: Relationshionship?
  @Published var favourites: [Status] = []
  private var favouritesNextPage: LinkHandler?
  @Published var followedTags: [Tag] = []
  @Published var featuredTags: [FeaturedTag] = []
  @Published var fields: [Account.Field] = []
  @Published var familliarFollowers: [Account] = []
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
    self.isCurrentUser = false
  }
  
  /// When the account is already fetched by the parent caller.
  init(account: Account) {
    self.accountId = account.id
    self.account = account
    self.accountState = .data(account: account)
  }
  
  func fetchAccount() async {
    guard let client else { return }
    do {
      async let account: Account = client.get(endpoint: Accounts.accounts(id: accountId))
      async let featuredTags: [FeaturedTag] = client.get(endpoint: Accounts.featuredTags(id: accountId))
      let loadedAccount = try await account
      self.account = loadedAccount
      self.featuredTags = try await featuredTags
      self.featuredTags.sort { $0.statusesCountInt > $1.statusesCountInt }
      self.fields = loadedAccount.fields
      if isCurrentUser {
        async let followedTags: [Tag] = client.get(endpoint: Accounts.followedTags)
        self.followedTags = try await followedTags
      } else {
        if client.isAuth {
          async let relationships: [Relationshionship] = client.get(endpoint: Accounts.relationships(ids: [accountId]))
          async let familliarFollowers: [FamilliarAccounts] = client.get(endpoint: Accounts.familiarFollowers(withAccount: accountId))
          self.relationship = try await relationships.first
          self.familliarFollowers = try await familliarFollowers.first?.accounts ?? []
        }
      }
      accountState = .data(account: loadedAccount)
    } catch {
      if let account {
        accountState = .data(account: account)
      } else {
        accountState = .error(error: error)
      }
    }
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
                                                       excludeReplies: selectedTab == .statuses && !isCurrentUser ? true : nil))
      if isCurrentUser {
        (favourites, favouritesNextPage) = try await client.getWithLink(endpoint: Accounts.favourites(sinceId: nil))
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
                                                         excludeReplies: selectedTab == .statuses && !isCurrentUser ? true : nil))
        statuses.append(contentsOf: newStatuses)
        tabState = .statuses(statusesState: .display(statuses: statuses,
                                                     nextPageState: newStatuses.count < 20 ? .none : .hasNextPage))
      case .favourites:
        guard let nextPageId = favouritesNextPage?.maxId else { return }
        let newFavourites: [Status]
        (newFavourites, favouritesNextPage) = try await client.getWithLink(endpoint: Accounts.favourites(sinceId: nextPageId))
        favourites.append(contentsOf: newFavourites)
        tabState = .statuses(statusesState: .display(statuses: favourites, nextPageState: .hasNextPage))
      case .followedTags, .lists:
        break
      }
    } catch {
      tabState = .statuses(statusesState: .error(error: error))
    }
  }
  
  func follow() async {
    guard let client else { return }
    do {
      relationship = try await client.post(endpoint: Accounts.follow(id: accountId))
    } catch {
      print("Error while following: \(error.localizedDescription)")
    }
  }
  
  func unfollow() async {
    guard let client else { return }
    do {
      relationship = try await client.post(endpoint: Accounts.unfollow(id: accountId))
    } catch {
      print("Error while unfollowing: \(error.localizedDescription)")
    }
  }
  
  private func reloadTabState() {
    switch selectedTab {
    case .statuses, .postsAndReplies, .media:
      tabState = .statuses(statusesState: .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage))
    case .favourites:
      tabState = .statuses(statusesState: .display(statuses: favourites,
                                                   nextPageState: favouritesNextPage != nil ? .hasNextPage : .none))
    case .followedTags:
      tabState = .followedTags(tags: followedTags)
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
