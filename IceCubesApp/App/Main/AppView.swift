import AVFoundation
import Account
import AppAccount
import DesignSystem
import Env
import KeychainSwift
import MediaUI
import Models
import NetworkClient
import RevenueCat
import StatusKit
import SwiftData
import SwiftUI
import Timeline

@MainActor
struct AppView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.openWindow) var openWindow
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher
  @Environment(CurrentAccount.self) private var currentAccount

  @Binding var selectedTab: AppTab
  @Binding var appRouterPath: RouterPath

  @State var iosTabs = iOSTabs.shared
  @State var selectedTabScrollToTop: Int = -1
  @State var timeline: TimelineFilter = .home

  @AppStorage("timeline_pinned_filters") private var pinnedFilters: [TimelineFilter] = []

  @Query(sort: \LocalTimeline.creationDate, order: .reverse) var localTimelines: [LocalTimeline]
  @Query(sort: \TagGroup.creationDate, order: .reverse) var tagGroups: [TagGroup]

  var body: some View {
    HStack(spacing: 0) {
      tabBarView
          .tabViewStyle(.sidebarAdaptable)
      if horizontalSizeClass == .regular
        && (UIDevice.current.userInterfaceIdiom == .pad
          || UIDevice.current.userInterfaceIdiom == .mac),
        appAccountsManager.currentClient.isAuth,
        userPreferences.showiPadSecondaryColumn
      {
        Divider().edgesIgnoringSafeArea(.all)
        notificationsSecondaryColumn
      }
    }
  }

  var availableSections: [SidebarSections] {
    guard appAccountsManager.currentClient.isAuth else {
      return [SidebarSections.loggedOutTabs]
    }
    if UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact {
      return [SidebarSections.iosTabs]
    } else if UIDevice.current.userInterfaceIdiom == .vision {
      return [SidebarSections.visionOSTabs]
    }
    var sections = SidebarSections.macOrIpadOSSections
    if !localTimelines.isEmpty {
      sections.append(.localTimeline)
    }
    if !tagGroups.isEmpty {
      sections.append(.tagGroup)
    }
    sections.append(.app)
    return sections
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
      ForEach(availableSections) { section in
        TabSection(section.title) {
          if section == .localTimeline {
            ForEach(localTimelines) { timeline in
              let tab = AppTab.anyTimelineFilter(
                filter: .remoteLocal(server: timeline.instance, filter: .local))
              Tab(value: tab) {
                tab.makeContentView(
                  homeTimeline: $timeline, selectedTab: $selectedTab, pinnedFilters: $pinnedFilters)
              } label: {
                tab.label.environment(\.symbolVariants, tab == selectedTab ? .fill : .none)
              }
              .tabPlacement(tab.tabPlacement)
            }
          } else if section == .tagGroup {
            ForEach(tagGroups) { tagGroup in
              let tab = AppTab.anyTimelineFilter(
                filter: TimelineFilter.tagGroup(
                  title: tagGroup.title,
                  tags: tagGroup.tags,
                  symbolName: tagGroup.symbolName))
              Tab(value: tab) {
                tab.makeContentView(
                  homeTimeline: $timeline, selectedTab: $selectedTab, pinnedFilters: $pinnedFilters)
              } label: {
                tab.label.environment(\.symbolVariants, tab == selectedTab ? .fill : .none)
              }
              .tabPlacement(tab.tabPlacement)
            }
          } else {
            ForEach(section.tabs) { tab in
              Tab(value: tab, role: tab == .explore ? .search : .none) {
                tab.makeContentView(
                  homeTimeline: $timeline, selectedTab: $selectedTab, pinnedFilters: $pinnedFilters)
              } label: {
                tab.label.environment(\.symbolVariants, tab == selectedTab ? .fill : .none)
              }
              .tabPlacement(tab.tabPlacement)
              .badge(badgeFor(tab: tab))
            }
          }
        }
        .tabPlacement(.sidebarOnly)
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
      selectedTabScrollToTop = newTab.id
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
