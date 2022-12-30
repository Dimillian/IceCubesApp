import SwiftUI
import Models
import Network

@MainActor
public class AppAccountViewModel: ObservableObject {
  let appAccount: AppAccount
  let client: Client
  
  @Published var account: Account?
  
  init(appAccount: AppAccount) {
    self.appAccount = appAccount
    self.client = .init(server: appAccount.server, oauthToken: appAccount.oauthToken)
  }
  
  func fetchAccount() async {
    do {
      account = try await client.get(endpoint: Accounts.verifyCredentials)
    } catch {
      print(error)
    }
  }
}
