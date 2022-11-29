import SwiftUI
import Network
import Models

@MainActor
class AccountDetailViewModel: ObservableObject {
  let accountId: String
  var client: Client = .init(server: "")
  
  enum State {
    case loading, data(account: Models.Account), error(error: Error)
  }
  
  @Published var state: State = .loading
  
  init(accountId: String) {
    self.accountId = accountId
  }
  
  func fetchAccount() async {
    do {
        state = .data(account: try await client.fetch(endpoint: Network.Account.accounts(id: accountId)))
    } catch {
      state = .error(error: error)
    }
  }
}
