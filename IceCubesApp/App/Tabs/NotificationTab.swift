import AppAccount
import DesignSystem
import Env
import Models
import Network
import Notifications
import SwiftUI
import Timeline

@MainActor
struct NotificationsTab: View {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.scenePhase) private var scenePhase

  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(StreamWatcher.self) private var watcher
  @Environment(AppAccountsManager.self) private var appAccount
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(PushNotificationsService.self) private var pushNotificationsService
  @State private var routerPath = RouterPath()
  @State private var scrollToTopSignal: Int = 0

  @Binding var selectedTab: Tab
  @Binding var popToRootTab: Tab

  let lockedType: Models.Notification.NotificationType?

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      NotificationsListView(lockedType: lockedType, scrollToTopSignal: $scrollToTopSignal)
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              routerPath.presentedSheet = .accountPushNotficationsSettings
            } label: {
              Image(systemName: "bell")
            }
          }
          ToolbarTab(routerPath: $routerPath)
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .navigationBar)
        .id(client.id)
    }
    .onAppear {
      routerPath.client = client
      clearNotifications()
    }
    .withSafariRouter()
    .environment(routerPath)
    .onChange(of: $popToRootTab.wrappedValue) { _, newValue in
      if newValue == .notifications {
        if routerPath.path.isEmpty {
          scrollToTopSignal += 1
        } else {
          routerPath.path = []
        }
      }
    }
    .onChange(of: selectedTab) { _, _ in
      clearNotifications()
    }
    .onChange(of: pushNotificationsService.handledNotification) { _, newValue in
      if let newValue, let type = newValue.notification.supportedType {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          switch type {
          case .follow, .follow_request:
            routerPath.navigate(to: .accountDetailWithAccount(account: newValue.notification.account))
          default:
            if let status = newValue.notification.status {
              routerPath.navigate(to: .statusDetailWithStatus(status: status))
            }
          }
        }
      }
    }
    .onChange(of: scenePhase) { _, newValue in
      switch newValue {
      case .active:
        clearNotifications()
      default:
        break
      }
    }
    .onChange(of: client.id) {
      routerPath.path = []
    }
  }

  private func clearNotifications() {
    if selectedTab == .notifications || isSecondaryColumn {
      if let token = appAccount.currentAccount.oauthToken {
        userPreferences.notificationsCount[token] = 0
      }
      watcher.unreadNotificationsCount = 0
    }
  }
}
