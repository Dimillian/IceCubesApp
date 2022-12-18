import SwiftUI
import Network
import Models

@MainActor
class AccountDetailViewModel: ObservableObject {
  let accountId: String
  var client: Client = .init(server: "")
  
  enum State {
    case loading, data(account: Account), error(error: Error)
  }
  
  enum StatusesState {
    enum PagingState {
      case hasNextPage, loadingNextPage
    }
    case loading
    case display(statuses: [Status], nextPageState: StatusesState.PagingState)
    case error(error: Error)
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
    do {
      state = .data(account: try await client.get(endpoint: Accounts.accounts(id: accountId)))
    } catch {
      state = .error(error: error)
    }
  }
  
  func fetchStatuses() async {
    do {
      statusesState = .loading
      statuses = try await client.get(endpoint: Accounts.statuses(id: accountId, sinceId: nil))
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }
  
  func loadNextPage() async {
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
