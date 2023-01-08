import SwiftUI
import Network
import Env

class AppAccountsManager: ObservableObject {
  @AppStorage("latestCurrentAccountKey") static public var latestCurrentAccountKey: String = ""
  
  @Published var currentAccount: AppAccount {
    didSet {
      Self.latestCurrentAccountKey = currentAccount.id
      currentClient = .init(server: currentAccount.server,
                            oauthToken: currentAccount.oauthToken)
    }
  }
  @Published var availableAccounts: [AppAccount]
  @Published var currentClient: Client
  
  var pushAccounts: [PushNotificationsService.PushAccounts] {
    availableAccounts.filter{ $0.oauthToken != nil}
      .map{ .init(server: $0.server, token: $0.oauthToken!) }
  }
  
  static var shared = AppAccountsManager()
  
  private init() {
    var defaultAccount = AppAccount(server: IceCubesApp.defaultServer, oauthToken: nil)
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
  
  func add(account: AppAccount) {
    do {
      try account.save()
      availableAccounts.append(account)
      currentAccount = account
    } catch { }
  }
  
  func delete(account: AppAccount) {
    availableAccounts.removeAll(where: { $0.id == account.id })
    account.delete()
    if currentAccount.id == account.id {
      currentAccount = availableAccounts.first ?? AppAccount(server: IceCubesApp.defaultServer, oauthToken: nil)
    }
  }
}
