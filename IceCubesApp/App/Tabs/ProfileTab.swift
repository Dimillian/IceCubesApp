import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

struct ProfileTab: View {
  @Environment(AppAccountsManager.self) private var appAccount
  @EnvironmentObject private var theme: Theme
  @Environment(Client.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount
  @State private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      if let account = currentAccount.account {
        AccountDetailView(account: account)
          .withAppRouter()
          .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
          .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
          .id(account.id)
      } else {
        AccountDetailView(account: .placeholder())
          .redacted(reason: .placeholder)
      }
    }
    .onChange(of: $popToRootTab.wrappedValue) { oldValue, newValue in
      if newValue == .profile {
        routerPath.path = []
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
