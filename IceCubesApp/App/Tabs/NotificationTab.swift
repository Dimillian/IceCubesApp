import SwiftUI
import Timeline
import Env
import Network
import Notifications

struct NotificationsTab: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var userPreferences: UserPreferences
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: Tab
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      NotificationsListView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          statusEditorToolbarItem(routeurPath: routeurPath,
                                  visibility: userPreferences.serverPreferences?.postVisibility ?? .pub)
          ToolbarItem(placement: .navigationBarLeading) {
            AppAccountsSelectorView(routeurPath: routeurPath)
          }
        }
        .id(currentAccount.account?.id)
    }
    .onAppear {
      routeurPath.client = client
      watcher.unreadNotificationsCount = 0
      userPreferences.pushNotificationsCount = 0
    }
    .withSafariRouteur()
    .environmentObject(routeurPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .notifications {
        routeurPath.path = []
      }
    }
    .onChange(of: currentAccount.account?.id) { _ in
      routeurPath.path = []
    }
  }
}
