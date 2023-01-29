import AppAccount
import DesignSystem
import Env
import Models
import Network
import Notifications
import SwiftUI
import Timeline

struct NotificationsTab: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var appAccount: AppAccountsManager
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var userPreferences: UserPreferences
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  let lockedType: Models.Notification.NotificationType?

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      NotificationsListView(lockedType: lockedType)
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          statusEditorToolbarItem(routerPath: routerPath,
                                  visibility: userPreferences.postVisibility)
          if UIDevice.current.userInterfaceIdiom != .pad {
            ToolbarItem(placement: .navigationBarLeading) {
              AppAccountsSelectorView(routerPath: routerPath)
            }
          }
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
        .id(appAccount.currentAccount.id)
    }
    .onAppear {
      routerPath.client = client
      watcher.unreadNotificationsCount = 0
      userPreferences.pushNotificationsCount = 0
    }
    .withSafariRouter()
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
