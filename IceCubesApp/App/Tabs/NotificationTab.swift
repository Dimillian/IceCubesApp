import SwiftUI
import Timeline
import Env
import Network
import Notifications
import AppAccount

struct NotificationsTab: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var userPreferences: UserPreferences
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab
  
  var body: some View {
    NavigationStack(path: $routerPath.path) {
      NotificationsListView()
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          statusEditorToolbarItem(routerPath: routerPath,
                                  visibility: userPreferences.serverPreferences?.postVisibility ?? .pub)
          if UIDevice.current.userInterfaceIdiom != .pad {
            ToolbarItem(placement: .navigationBarLeading) {
              AppAccountsSelectorView(routerPath: routerPath)
            }
          }
        }
        .id(currentAccount.account?.id)
    }
    .onAppear {
      routerPath.client = client
      watcher.unreadNotificationsCount = 0
      userPreferences.pushNotificationsCount = 0
    }
    .withSafariRouteur()
    .environmentObject(routerPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .notifications {
        routerPath.path = []
      }
    }
    .onChange(of: currentAccount.account?.id) { _ in
      routerPath.path = []
    }
  }
}
