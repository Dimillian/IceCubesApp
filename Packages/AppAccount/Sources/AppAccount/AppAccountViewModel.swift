import DesignSystem
import Models
import Network
import SwiftUI

@MainActor
public class AppAccountViewModel: ObservableObject {
  private static var avatarsCache: [String: UIImage] = [:]

  var appAccount: AppAccount
  let client: Client
  let isCompact: Bool

  @Published var account: Account?
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
      account = try await client.get(endpoint: Accounts.verifyCredentials)
      if appAccount.accountName == nil, let account {
        appAccount.accountName = "\(account.acct)@\(appAccount.server)"
        try appAccount.save()
      }

      if let account {
        if let image = Self.avatarsCache[account.id] {
          roundedAvatar = image
        } else if let (data, _) = try? await URLSession.shared.data(from: account.avatar),
                  let image = UIImage(data: data)?.roundedImage
        {
          roundedAvatar = image
          Self.avatarsCache[account.id] = image
        }
      }

    } catch {}
  }
}
