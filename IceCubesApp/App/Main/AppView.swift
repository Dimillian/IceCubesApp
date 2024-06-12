import Account
import AppAccount
import AVFoundation
import DesignSystem
import Env
import KeychainSwift
import MediaUI
import Network
import RevenueCat
import StatusKit
import SwiftUI
import Timeline

@MainActor
struct AppView: View {
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher

  @Environment(\.openWindow) var openWindow
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Binding var selectedTab: Tab
  @Binding var appRouterPath: RouterPath

  @State var popToRootTab: Tab = .other
  @State var iosTabs = iOSTabs.shared
  @State var sidebarTabs = SidebarTabs.shared

  var body: some View {
    #if os(visionOS)
      tabBarView
    #else
      if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
        sidebarView
      } else {
        tabBarView
      }
    #endif
  }

  var availableTabs: [Tab] {
    guard appAccountsManager.currentClient.isAuth else {
      return Tab.loggedOutTab()
    }
    if UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact {
      return iosTabs.tabs
    } else if UIDevice.current.userInterfaceIdiom == .vision {
      return Tab.visionOSTab()
    }
    return sidebarTabs.tabs.map { $0.tab }
  }

  var tabBarView: some View {
    TabView(selection: .init(get: {
      selectedTab
    }, set: { newTab in
      if newTab == .post {
        #if os(visionOS)
          openWindow(value: WindowDestinationEditor.newStatusEditor(visibility: userPreferences.postVisibility))
        #else
          appRouterPath.presentedSheet = .newStatusEditor(visibility: userPreferences.postVisibility)
        #endif
        return
      }
      if newTab == selectedTab {
        /// Stupid hack to trigger onChange binding in tab views.
        popToRootTab = .other
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          popToRootTab = selectedTab
        }
      }

      HapticManager.shared.fireHaptic(.tabSelection)
      SoundEffectManager.shared.playSound(.tabSelection)

      selectedTab = newTab
    })) {
      ForEach(availableTabs) { tab in
        tab.makeContentView(selectedTab: $selectedTab, popToRootTab: $popToRootTab)
          .tabItem {
            if userPreferences.showiPhoneTabLabel {
              tab.label
                .environment(\.symbolVariants, tab == selectedTab ? .fill : .none)
            } else {
              Image(systemName: tab.iconName)
            }
          }
          .tag(tab)
          .badge(badgeFor(tab: tab))
          .toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .tabBar)
      }
    }
    .id(appAccountsManager.currentClient.id)
    .withSheetDestinations(sheetDestinations: $appRouterPath.presentedSheet)
  }

  private func badgeFor(tab: Tab) -> Int {
    if tab == .notifications, selectedTab != tab,
       let token = appAccountsManager.currentAccount.oauthToken
    {
      return watcher.unreadNotificationsCount + (userPreferences.notificationsCount[token] ?? 0)
    }
    return 0
  }

  #if !os(visionOS)
    var sidebarView: some View {
      SideBarView(selectedTab: $selectedTab,
                  popToRootTab: $popToRootTab,
                  tabs: availableTabs)
      {
        HStack(spacing: 0) {
          TabView(selection: $selectedTab) {
            ForEach(availableTabs) { tab in
              tab
                .makeContentView(selectedTab: $selectedTab, popToRootTab: $popToRootTab)
                .tabItem {
                  tab.label
                }
                .tag(tab)
            }
          }
          .introspect(.tabView, on: .iOS(.v17, .v18)) { (tabview: UITabBarController) in
            tabview.tabBar.isHidden = horizontalSizeClass == .regular
            tabview.customizableViewControllers = []
            tabview.moreNavigationController.isNavigationBarHidden = true
          }
          if horizontalSizeClass == .regular,
             appAccountsManager.currentClient.isAuth,
             userPreferences.showiPadSecondaryColumn
          {
            Divider().edgesIgnoringSafeArea(.all)
            notificationsSecondaryColumn
          }
        }
      }
      .environment(appRouterPath)
    }
  #endif

  var notificationsSecondaryColumn: some View {
    NotificationsTab(selectedTab: .constant(.notifications),
                     popToRootTab: $popToRootTab, lockedType: nil)
      .environment(\.isSecondaryColumn, true)
      .frame(maxWidth: .secondaryColumnWidth)
      .id(appAccountsManager.currentAccount.id)
  }
}
