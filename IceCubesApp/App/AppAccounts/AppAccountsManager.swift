import SwiftUI
import Network

class AppAccountsManager: ObservableObject {
  @Published var currentAccount: AppAccount {
    didSet {
      currentClient = .init(server: currentAccount.server,
                            oauthToken: currentAccount.oauthToken)
    }
  }
  @Published var availableAccounts: [AppAccount]
  @Published var currentClient: Client
  
  init() {
    var defaultAccount = AppAccount(server: IceCubesApp.defaultServer, oauthToken: nil)
    do {
      let keychainAccounts = try AppAccount.retrieveAll()
      availableAccounts = keychainAccounts
      defaultAccount = keychainAccounts.last ?? defaultAccount
    } catch {}
    currentAccount = defaultAccount
    availableAccounts = [defaultAccount]
    currentClient = .init(server: defaultAccount.server, oauthToken: defaultAccount.oauthToken)
  }
  
  func add(account: AppAccount) {
    do {
      try account.save()
      currentAccount = account
    } catch { }
  }
  
  func delete(account: AppAccount) {
    account.delete()
    AppAccount.deleteAll()
    currentAccount = AppAccount(server: IceCubesApp.defaultServer, oauthToken: nil)
  }
}
