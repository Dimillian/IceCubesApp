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
  
  private var statuses: [Status] = []
  
  init(accountId: String) {
    self.accountId = accountId
  }
  
  init(account: Account) {
    self.accountId = account.id
    self.state = .data(account: account)
  }
  
  func fetchAccount() async {
    guard let client else { return }
    do {
      state = .data(account: try await client.get(endpoint: Accounts.accounts(id: accountId)))
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
}
