import Models
import Network
import SwiftUI

@MainActor
public class AppAccountViewModel: ObservableObject {
  var appAccount: AppAccount
  let client: Client
  let isCompact: Bool

  @Published var account: Account?

  var acct: String {
    "@\(account?.acct ?? "...")@\(appAccount.server)"
  }

  public init(appAccount: AppAccount, isCompact: Bool = false) {
    self.appAccount = appAccount
    self.isCompact = isCompact
    client = .init(server: appAccount.server, oauthToken: appAccount.oauthToken)
  }

  func fetchAccount() async {
    do {
      account = try await client.get(endpoint: Accounts.verifyCredentials)
      if appAccount.accountName == nil, let account {
        appAccount.accountName = "\(account.acct)@\(appAccount.server)"
        try appAccount.save()
      }
    } catch {
      print(error)
    }
  }
}
