import AVFoundation
import Account
import AppAccount
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

  @Binding var selectedTab: AppTab
  @Binding var appRouterPath: RouterPath

  @State var iosTabs = iOSTabs.shared
  @State var sidebarTabs = SidebarTabs.shared
  @State var selectedTabScrollToTop: Int = -1
  @State var timeline: TimelineFilter = .home

  @AppStorage("timeline_pinned_filters") private var pinnedFilters: [TimelineFilter] = []

  var body: some View {
    HStack(spacing: 0) {
      if #available(iOS 26, *) {
        tabBarView
          .tabViewBottomAccessory {
            if !pinnedFilters.isEmpty {
              TimelineQuickAccessPills(pinnedFilters: $pinnedFilters, timeline: $timeline)
                .padding(.horizontal, 8)
                .onChange(of: timeline) { _, _ in
                  if selectedTab != .timeline {
                    selectedTab = .timeline
                  }
                }
            }
          }
          .tabBarMinimizeBehavior(.never)
          .tabViewStyle(.sidebarAdaptable)
      } else {
        tabBarView
      }
      
      if horizontalSizeClass == .regular,
         appAccountsManager.currentClient.isAuth,
         userPreferences.showiPadSecondaryColumn {
        Divider().edgesIgnoringSafeArea(.all)
        notificationsSecondaryColumn
      }
    }
  }

  var availableTabs: [AppTab] {
    guard appAccountsManager.currentClient.isAuth else {
      return AppTab.loggedOutTab()
    }
    if UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact {
      return iosTabs.tabs
    } else if UIDevice.current.userInterfaceIdiom == .vision {
      return AppTab.visionOSTab()
    }
    return sidebarTabs.tabs.map { $0.tab }
  }

  @ViewBuilder
  var tabBarView: some View {
    TabView(
      selection: .init(
        get: {
          selectedTab
        },
        set: { newTab in
          updateTab(with: newTab)
        })
    ) {
      ForEach(availableTabs) { tab in
        tab.makeContentView(
          homeTimeline: $timeline, selectedTab: $selectedTab, pinnedFilters: $pinnedFilters
        )
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
    .environment(\.selectedTabScrollToTop, selectedTabScrollToTop)
  }

  private func updateTab(with newTab: AppTab) {
    if newTab == .post {
      #if os(visionOS)
        openWindow(
          value: WindowDestinationEditor.newStatusEditor(visibility: userPreferences.postVisibility)
        )
      #else
        appRouterPath.presentedSheet = .newStatusEditor(visibility: userPreferences.postVisibility)
      #endif
      return
    }

    HapticManager.shared.fireHaptic(.tabSelection)
    SoundEffectManager.shared.playSound(.tabSelection)

    if selectedTab == newTab {
      selectedTabScrollToTop = newTab.rawValue
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        selectedTabScrollToTop = -1
      }
    } else {
      selectedTabScrollToTop = -1
    }

    selectedTab = newTab
  }

  private func badgeFor(tab: AppTab) -> Int {
    if tab == .notifications, selectedTab != tab,
      let token = appAccountsManager.currentAccount.oauthToken
    {
      return watcher.unreadNotificationsCount + (userPreferences.notificationsCount[token] ?? 0)
    }
    return 0
  }

  var notificationsSecondaryColumn: some View {
    NotificationsTab(selectedTab: .constant(.notifications), lockedType: nil)
      .environment(\.isSecondaryColumn, true)
      .frame(maxWidth: .secondaryColumnWidth)
      .id(appAccountsManager.currentAccount.id)
  }
}
