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
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      if let account = currentAccount.account {
        AccountDetailView(account: account)
          .withAppRouter()
          .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
          .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
          .id(currentAccount.account?.id)
      } else {
        AccountDetailView(account: .placeholder())
          .redacted(reason: .placeholder)
          .shimmering()
      }
    }
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .profile {
        routerPath.path = []
      }
    }
    .onChange(of: currentAccount.account?.id) { _ in
      routerPath.path = []
    }
    .onAppear {
      routerPath.client = client
    }
    .withSafariRouter()
    .environmentObject(routerPath)
  }
}
