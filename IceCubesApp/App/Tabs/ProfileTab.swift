import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
struct ProfileTab: View {
  @Environment(AppAccountsManager.self) private var appAccount
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount
  @State private var routerPath = RouterPath()

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      if let account = currentAccount.account {
        AccountDetailView(account: account)
          .withAppRouter()
          .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
          .toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .navigationBar)
          .id(account.id)
      } else {
        AccountDetailView(account: .placeholder())
          .redacted(reason: .placeholder)
          .allowsHitTesting(false)
      }
    }
    .onChange(of: client.id) {
      routerPath.path = []
    }
    .onAppear {
      routerPath.client = client
    }
    .withSafariRouter()
    .environment(routerPath)
  }
}
