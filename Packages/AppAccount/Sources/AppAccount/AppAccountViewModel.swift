import Combine
import DesignSystem
import Models
import Network
import SwiftUI

@MainActor
public class AppAccountViewModel: ObservableObject {
  private static var avatarsCache: [String: UIImage] = [:]
  private static var accountsCache: [String: Account] = [:]

  var appAccount: AppAccount
  let client: Client
  let isCompact: Bool

  @Published var account: Account? {
    didSet {
      if let account {
        refreshAcct(account: account)
      }
    }
  }

  @Published var roundedAvatar: UIImage?

  var acct: String {
    if let acct = appAccount.accountName {
      return acct
    } else {
      return "@\(account?.acct ?? "...")@\(appAccount.server)"
    }
  }

  public init(appAccount: AppAccount, isCompact: Bool = false) {
    self.appAccount = appAccount
    self.isCompact = isCompact
    client = .init(server: appAccount.server, oauthToken: appAccount.oauthToken)
  }

  func fetchAccount() async {
    do {
      account = Self.accountsCache[appAccount.id]
      roundedAvatar = Self.avatarsCache[appAccount.id]

      account = try await client.get(endpoint: Accounts.verifyCredentials)
      Self.accountsCache[appAccount.id] = account

      if let account {
        await refreshAvatar(account: account)
      }

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

  private func refreshAvatar(account: Account) async {
    // Warning: Non-sendable type '(any URLSessionTaskDelegate)?' exiting main actor-isolated
    // context in call to non-isolated instance method 'data(for:delegate:)' cannot cross actor
    // boundary.
    // This is on the defaulted-to-nil second parameter of `.data(from:delegate:)`.
    // There is a Radar tracking this & others like it.
    if let (data, _) = try? await URLSession.shared.data(from: account.avatar),
       let image = UIImage(data: data)?.roundedImage
    {
      roundedAvatar = image
      Self.avatarsCache[account.id] = image
    }
  }
}
