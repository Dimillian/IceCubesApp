import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Models
import Network
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

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      ConversationsListView(scrollToTopSignal: $scrollToTopSignal)
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          ToolbarTab(routerPath: $routerPath)
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .navigationBar)
        .id(client.id)
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
