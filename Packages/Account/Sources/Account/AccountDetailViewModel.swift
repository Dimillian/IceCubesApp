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
  
  enum Tab: Int, CaseIterable {
    case statuses, favourites, followedTags
    
    var title: String {
      switch self {
      case .statuses: return "Posts"
      case .favourites: return "Favourites"
      case .followedTags: return "Followed Tags"
      }
    }
  }
  
  enum TabState {
    case followedTags(tags: [Tag])
    case statuses(statusesState: StatusesState)
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
  
  @Published var title: String = ""
  @Published var relationship: Relationshionship?
  @Published var favourites: [Status] = []
  private var favouritesNextPage: LinkHandler?
  @Published var followedTags: [Tag] = []
  @Published var featuredTags: [FeaturedTag] = []
  @Published var fields: [Account.Field] = []
  @Published var familliarFollowers: [Account] = []
  @Published var selectedTab = Tab.statuses {
    didSet {
      reloadTabState()
    }
  }
  
  private var account: Account?
  
  private(set) var statuses: [Status] = []
  
  /// When coming from a URL like a mention tap in a status.
  init(accountId: String) {
    self.accountId = accountId
    self.isCurrentUser = false
  }
  
  /// When the account is already fetched by the parent caller.
  init(account: Account) {
    self.accountId = account.id
    self.accountState = .data(account: account)
  }
  
  func fetchAccount() async {
    guard let client else { return }
    do {
      async let account: Account = client.get(endpoint: Accounts.accounts(id: accountId))
      async let followedTags: [Tag] = client.get(endpoint: Accounts.followedTags)
      async let relationships: [Relationshionship] = client.get(endpoint: Accounts.relationships(ids: [accountId]))
      async let featuredTags: [FeaturedTag] = client.get(endpoint: Accounts.featuredTags(id: accountId))
      async let familliarFollowers: [FamilliarAccounts] = client.get(endpoint: Accounts.familiarFollowers(withAccount: accountId))
      let loadedAccount = try await account
      self.featuredTags = try await featuredTags
      self.featuredTags.sort { $0.statusesCountInt > $1.statusesCountInt }
      self.fields = loadedAccount.fields
      self.title = loadedAccount.displayName
      if isCurrentUser {
        self.followedTags = try await followedTags
      } else {
        let relationships = try await relationships
        self.relationship = relationships.first
        self.familliarFollowers = try await familliarFollowers.first?.accounts ?? []
      }
      self.account = loadedAccount
      accountState = .data(account: loadedAccount)
    } catch {
      accountState = .error(error: error)
    }
  }
  
  func fetchStatuses() async {
    guard let client else { return }
    do {
      tabState = .statuses(statusesState: .loading)
      statuses = try await client.get(endpoint: Accounts.statuses(id: accountId, sinceId: nil, tag: nil))
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
      case .statuses:
        guard let lastId = statuses.last?.id else { return }
        tabState = .statuses(statusesState: .display(statuses: statuses, nextPageState: .loadingNextPage))
        let newStatuses: [Status] = try await client.get(endpoint: Accounts.statuses(id: accountId, sinceId: lastId, tag: nil))
        statuses.append(contentsOf: newStatuses)
        tabState = .statuses(statusesState: .display(statuses: statuses, nextPageState: .hasNextPage))
      case .favourites:
        guard let nextPageId = favouritesNextPage?.maxId else { return }
        let newFavourites: [Status]
        (newFavourites, favouritesNextPage) = try await client.getWithLink(endpoint: Accounts.favourites(sinceId: nextPageId))
        favourites.append(contentsOf: newFavourites)
        tabState = .statuses(statusesState: .display(statuses: favourites, nextPageState: .hasNextPage))
      case .followedTags:
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
    case .statuses:
      tabState = .statuses(statusesState: .display(statuses: statuses, nextPageState: .hasNextPage))
    case .favourites:
      tabState = .statuses(statusesState: .display(statuses: favourites,
                                                   nextPageState: favouritesNextPage != nil ? .hasNextPage : .none))
    case .followedTags:
      tabState = .followedTags(tags: followedTags)
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
