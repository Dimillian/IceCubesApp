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
  
  @Published var state: State = .loading
  
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
}
