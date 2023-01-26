import Env
import Models
import Network
import SwiftUI

@MainActor
public class AppAccountsManager: ObservableObject {
  @AppStorage("latestCurrentAccountKey", store: UserPreferences.sharedDefault)
  public static var latestCurrentAccountKey: String = ""

  @Published public var currentAccount: AppAccount {
    didSet {
      Self.latestCurrentAccountKey = currentAccount.id
      currentClient = .init(server: currentAccount.server,
                            oauthToken: currentAccount.oauthToken)
    }
  }

  @Published public var availableAccounts: [AppAccount]
  @Published public var currentClient: Client

  public var pushAccounts: [PushAccount] {
    availableAccounts.filter { $0.oauthToken != nil }
      .map { .init(server: $0.server, token: $0.oauthToken!, accountName: $0.accountName) }
  }

  public static var shared = AppAccountsManager()

  internal init() {
    var defaultAccount = AppAccount(server: AppInfo.defaultServer, accountName: nil, oauthToken: nil)
    let keychainAccounts = AppAccount.retrieveAll()
    availableAccounts = keychainAccounts
    if let currentAccount = keychainAccounts.first(where: { $0.id == Self.latestCurrentAccountKey }) {
      defaultAccount = currentAccount
    } else {
      defaultAccount = keychainAccounts.last ?? defaultAccount
    }
    currentAccount = defaultAccount
    currentClient = .init(server: defaultAccount.server, oauthToken: defaultAccount.oauthToken)
  }

  public func add(account: AppAccount) {
    do {
      try account.save()
      availableAccounts.append(account)
      currentAccount = account
    } catch {}
  }

  public func delete(account: AppAccount) {
    availableAccounts.removeAll(where: { $0.id == account.id })
    account.delete()
    if currentAccount.id == account.id {
      currentAccount = availableAccounts.first ?? AppAccount(server: AppInfo.defaultServer,
                                                             accountName: nil,
                                                             oauthToken: nil)
    }
  }
}
