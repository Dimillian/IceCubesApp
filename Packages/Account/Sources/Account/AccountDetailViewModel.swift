import SwiftUI
import Network
import Models
import Status

@MainActor
class AccountDetailViewModel: ObservableObject, StatusesFetcher {
  let accountId: String
  var client: Client?
  
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
  @Published var followedTags: [Tag] = []
  @Published var featuredTags: [FeaturedTag] = []
  @Published var fields: [Account.Field] = []
  @Published var selectedTab = Tab.statuses {
    didSet {
      reloadTabState()
    }
  }
  
  private var account: Account?
  
  private(set) var statuses: [Status] = []
  private let isCurrentUser: Bool
  
  /// When coming from a URL like a mention tap in a status.
  init(accountId: String) {
    self.accountId = accountId
    self.isCurrentUser = false
  }
  
  /// When the account is already fetched by the parent caller.
  init(account: Account, isCurrentUser: Bool) {
    self.accountId = account.id
    self.accountState = .data(account: account)
    self.isCurrentUser = isCurrentUser
  }
  
  func fetchAccount() async {
    guard let client else { return }
    do {
      let account: Account = try await client.get(endpoint: Accounts.accounts(id: accountId))
      self.fields = account.fields
      if isCurrentUser {
        self.followedTags = try await client.get(endpoint: Accounts.followedTags)
      } else {
        let relationships: [Relationshionship] = try await client.get(endpoint: Accounts.relationships(id: accountId))
        self.relationship = relationships.first
      }
      self.featuredTags = try await client.get(endpoint: Accounts.featuredTags(id: accountId))
      self.featuredTags.sort { $0.statusesCountInt > $1.statusesCountInt }
      self.title = account.displayName
      accountState = .data(account: account)
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
        favourites = try await client.get(endpoint: Accounts.favourites)
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
      case .favourites, .followedTags:
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
      tabState = .statuses(statusesState: .display(statuses: favourites, nextPageState: .none))
    case .followedTags:
      tabState = .followedTags(tags: followedTags)
    }
  }
}
