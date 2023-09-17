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
  @Environment(StreamWatcher.self) private var watcher
  @Environment(Client.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(AppAccountsManager.self) private var appAccount
  @State private var routerPath = RouterPath()
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
        .id(client.id)
    }
    .onChange(of: $popToRootTab.wrappedValue) { oldValue, newValue in
      if newValue == .messages {
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
