import SwiftUI
import Models
import Network

public enum AccountsListMode: String {
  case following, followers
}

@MainActor
class AccountsListViewModel: ObservableObject {
  var client: Client?
  
  let accountId: String
  let mode: AccountsListMode
  
  public enum State {
    public enum PagingState {
      case hasNextPage, loadingNextPage, none
    }
    case loading
    case display(accounts: [Account],
                 relationships: [Relationshionship],
                 nextPageState: PagingState)
    case error(error: Error)
  }
  
  private var accounts: [Account] = []
  private var relationships: [Relationshionship] = []
  
  @Published var state = State.loading
  
  private var nextPageId: String?
  
  init(accountId: String, mode: AccountsListMode) {
    self.accountId = accountId
    self.mode = mode
  }
  
  func fetch() async {
    guard let client else { return }
    do {
      state = .loading
      let link: LinkHandler?
      switch mode {
      case .followers:
        (accounts, link) = try await client.getWithLink(endpoint: Accounts.followers(id: accountId,
                                                                                     sinceId: nil))
      case .following:
        (accounts, link) = try await client.getWithLink(endpoint: Accounts.following(id: accountId,
                                                                                     sinceId: nil))
      }
      nextPageId = link?.maxId
      relationships = try await client.get(endpoint:
                                            Accounts.relationships(ids: accounts.map{ $0.id }))
      state = .display(accounts: accounts,
                       relationships: relationships,
                       nextPageState: .hasNextPage)
    } catch { }
  }
  
  func fetchNextPage() async {
    guard let client, let nextPageId else { return }
    do {
      state = .display(accounts: accounts, relationships: relationships, nextPageState: .loadingNextPage)
      let newAccounts: [Account]
      let link: LinkHandler?
      switch mode {
      case .followers:
        (newAccounts, link) = try await client.getWithLink(endpoint: Accounts.followers(id: accountId,
                                                                                        sinceId: nextPageId))
      case .following:
        (newAccounts, link) = try await client.getWithLink(endpoint: Accounts.following(id: accountId,
                                                                                        sinceId: nextPageId))
      }
      accounts.append(contentsOf: newAccounts)
      let newRelationships: [Relationshionship] =
      try await client.get(endpoint: Accounts.relationships(ids: newAccounts.map{ $0.id }))
      
      relationships.append(contentsOf: newRelationships)
      self.nextPageId = link?.maxId
      state = .display(accounts: accounts,
                       relationships: relationships,
                       nextPageState: .hasNextPage)
    } catch {
      print(error)
    }
  }
}
