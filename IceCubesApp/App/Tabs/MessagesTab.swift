import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

struct MessagesTab: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var appAccount: AppAccountsManager
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      ConversationsListView()
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          if UIDevice.current.userInterfaceIdiom != .pad {
            ToolbarItem(placement: .navigationBarLeading) {
              AppAccountsSelectorView(routerPath: routerPath)
            }
          }
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
        .id(appAccount.currentAccount.id)
    }
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .messages {
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
