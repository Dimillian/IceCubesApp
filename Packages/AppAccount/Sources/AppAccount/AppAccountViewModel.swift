import Combine
import DesignSystem
import Models
import NetworkClient
import Observation
import SwiftUI

@MainActor
@Observable public class AppAccountViewModel {
  private static var avatarsCache: [String: UIImage] = [:]
  private static var accountsCache: [String: Account] = [:]

  var appAccount: AppAccount
  let client: MastodonClient
  let isCompact: Bool
  let isInSettings: Bool
  let showBadge: Bool

  var account: Account? {
    didSet {
      if let account {
        refreshAcct(account: account)
      }
    }
  }

  var acct: String {
    if let acct = appAccount.accountName {
      acct
    } else {
      "@\(account?.acct ?? "...")@\(appAccount.server)"
    }
  }

  public init(
    appAccount: AppAccount, isCompact: Bool = false, isInSettings: Bool = true,
    showBadge: Bool = false
  ) {
    self.appAccount = appAccount
    self.isCompact = isCompact
    self.isInSettings = isInSettings
    self.showBadge = showBadge
    client = .init(server: appAccount.server, oauthToken: appAccount.oauthToken)
  }

  func fetchAccount() async {
    do {
      account = Self.accountsCache[appAccount.id]

      account = try await client.get(endpoint: Accounts.verifyCredentials)
      Self.accountsCache[appAccount.id] = account
    } catch {}
  }

  private func refreshAcct(account: Account) {
    do {
      if appAccount.accountName == nil {
        appAccount.accountName = "\(account.acct)@\(appAccount.server)"
        try appAccount.save()
      }
    } catch {}
  }
}
