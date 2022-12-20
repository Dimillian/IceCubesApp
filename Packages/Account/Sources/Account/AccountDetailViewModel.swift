import SwiftUI
import Network
import Models
import Status

@MainActor
class AccountDetailViewModel: ObservableObject, StatusesFetcher {
  let accountId: String
  var client: Client?
  
  enum State {
    case loading, data(account: Account), error(error: Error)
  }

  
  @Published var state: State = .loading
  @Published var statusesState: StatusesState = .loading
  @Published var title: String = ""
  @Published var relationship: Relationshionship?
  
  private var account: Account?
  
  private(set) var statuses: [Status] = []
  private let isCurrentUser: Bool
  
  init(accountId: String) {
    self.accountId = accountId
    self.isCurrentUser = false
  }
  
  init(account: Account, isCurrentUser: Bool) {
    self.accountId = account.id
    self.state = .data(account: account)
    self.isCurrentUser = isCurrentUser
  }
  
  func fetchAccount() async {
    guard let client else { return }
    do {
      let account: Account = try await client.get(endpoint: Accounts.accounts(id: accountId))
      if !isCurrentUser {
        let relationships: [Relationshionship] = try await client.get(endpoint: Accounts.relationships(id: accountId))
        self.relationship = relationships.first
      }
      self.title = account.displayName
      state = .data(account: account)
    } catch {
      state = .error(error: error)
    }
  }
  
  func fetchStatuses() async {
    guard let client else { return }
    do {
      statusesState = .loading
      statuses = try await client.get(endpoint: Accounts.statuses(id: accountId, sinceId: nil))
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }
  
  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = statuses.last?.id else { return }
      statusesState = .display(statuses: statuses, nextPageState: .loadingNextPage)
      let newStatuses: [Status] = try await client.get(endpoint: Accounts.statuses(id: accountId, sinceId: lastId))
      statuses.append(contentsOf: newStatuses)
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
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
}
