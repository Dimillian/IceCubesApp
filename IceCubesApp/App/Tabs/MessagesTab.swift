import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

@MainActor
struct MessagesTab: View {
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher
  @Environment(Client.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(AppAccountsManager.self) private var appAccount
  @State private var routerPath = RouterPath()
  @State private var scrollToTopSignal: Int = 0
  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      ConversationsListView(scrollToTopSignal: $scrollToTopSignal)
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
        .id(client.id)
    }
    .onChange(of: $popToRootTab.wrappedValue) { _, newValue in
      if newValue == .messages {
        if routerPath.path.isEmpty {
          scrollToTopSignal += 1
        } else {
          routerPath.path = []
        }
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
