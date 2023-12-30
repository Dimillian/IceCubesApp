import Account
import AppAccount
import AVFoundation
import DesignSystem
import Env
import KeychainSwift
import MediaUI
import Network
import RevenueCat
import Status
import SwiftUI
import Timeline

@MainActor
struct AppView: View {
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher
  
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  
  @Binding var selectedTab: Tab
  @Binding var sidebarRouterPath: RouterPath
  
  @State var popToRootTab: Tab = .other
  @State var iosTabs = iOSTabs.shared
  @State var sideBarLoadedTabs: Set<Tab> = Set()
  
  var body: some View {
    if (UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac) &&
        horizontalSizeClass == .regular {
      sidebarView
    } else {
      tabBarView
    }
  }
  
  var availableTabs: [Tab] {
    if UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact {
      return appAccountsManager.currentClient.isAuth ? iosTabs.tabs : Tab.loggedOutTab()
    }
    return appAccountsManager.currentClient.isAuth ? Tab.loggedInTabs() : Tab.loggedOutTab()
  }

  var tabBarView: some View {
    TabView(selection: .init(get: {
      selectedTab
    }, set: { newTab in
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
            } else {
              Image(systemName: tab.iconName)
            }
          }
          .tag(tab)
          .badge(badgeFor(tab: tab))
          .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .tabBar)
      }
    }
    .id(appAccountsManager.currentClient.id)
  }

  private func badgeFor(tab: Tab) -> Int {
    if tab == .notifications, selectedTab != tab,
       let token = appAccountsManager.currentAccount.oauthToken
    {
      return watcher.unreadNotificationsCount + (userPreferences.notificationsCount[token] ?? 0)
    }
    return 0
  }
  
  var sidebarView: some View {
    SideBarView(selectedTab: $selectedTab,
                popToRootTab: $popToRootTab,
                tabs: availableTabs)
    {
      HStack(spacing: 0) {
        ZStack {
          if selectedTab == .profile {
            ProfileTab(popToRootTab: $popToRootTab)
          }
          ForEach(availableTabs) { tab in
            if tab == selectedTab || sideBarLoadedTabs.contains(tab) {
              tab
                .makeContentView(selectedTab: $selectedTab, popToRootTab: $popToRootTab)
                .opacity(tab == selectedTab ? 1 : 0)
                .transition(.opacity)
                .id("\(tab)\(appAccountsManager.currentAccount.id)")
                .onAppear {
                  sideBarLoadedTabs.insert(tab)
                }
            } else {
              EmptyView()
            }
          }
        }
        if appAccountsManager.currentClient.isAuth,
           userPreferences.showiPadSecondaryColumn
        {
          Divider().edgesIgnoringSafeArea(.all)
          notificationsSecondaryColumn
        }
      }
    }.onChange(of: appAccountsManager.currentAccount.id) {
      sideBarLoadedTabs.removeAll()
    }
    .environment(sidebarRouterPath)
  }

  var notificationsSecondaryColumn: some View {
    NotificationsTab(selectedTab: .constant(.notifications),
                     popToRootTab: $popToRootTab, lockedType: nil)
      .environment(\.isSecondaryColumn, true)
      .frame(maxWidth: .secondaryColumnWidth)
      .id(appAccountsManager.currentAccount.id)
  }
}

