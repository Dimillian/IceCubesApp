import Account
import AppIntents
import DesignSystem
import Explore
import Foundation
import StatusKit
import SwiftUI
import Timeline

@MainActor
enum AppTab: Int, Identifiable, Hashable, CaseIterable, Codable {
  case timeline, notifications, mentions, explore, messages, settings, other
  case trending, federated, local
  case profile
  case bookmarks
  case favorites
  case post
  case followedTags
  case lists
  case links

  nonisolated var id: Int {
    rawValue
  }

  static func loggedOutTab() -> [AppTab] {
    [.timeline, .settings]
  }

  static func visionOSTab() -> [AppTab] {
    [.profile, .timeline, .notifications, .mentions, .explore, .post, .settings]
  }

  @ViewBuilder
  func makeContentView(
    homeTimeline: Binding<TimelineFilter>,
    selectedTab: Binding<AppTab>,
    pinnedFilters: Binding<[TimelineFilter]>
  ) -> some View {
    switch self {
    case .timeline:
      TimelineTab(canFilterTimeline: true, timeline: homeTimeline, pinedFilters: pinnedFilters)
    case .trending:
      TimelineTab(timeline: .constant(.trending))
    case .local:
      TimelineTab(timeline: .constant(.local))
    case .federated:
      TimelineTab(timeline: .constant(.federated))
    case .notifications:
      NotificationsTab(selectedTab: selectedTab, lockedType: nil)
    case .mentions:
      NotificationsTab(selectedTab: selectedTab, lockedType: .mention)
    case .explore:
      ExploreTab()
    case .messages:
      MessagesTab()
    case .settings:
      SettingsTabs(isModal: false)
    case .profile:
      ProfileTab()
    case .bookmarks:
      NavigationTab {
        AccountStatusesListView(mode: .bookmarks)
      }
    case .favorites:
      NavigationTab {
        AccountStatusesListView(mode: .favorites)
      }
    case .followedTags:
      NavigationTab {
        FollowedTagsListView()
      }
    case .lists:
      NavigationTab {
        ListsListView()
      }
    case .links:
      NavigationTab { TrendingLinksListView(cards: []) }
    case .post:
      VStack {}
    case .other:
      EmptyView()
    }
  }

  var tabPlacement: TabPlacement {
    switch self {
    case .timeline, .notifications, .explore, .links, .profile:
      return .pinned
    default:
      return .sidebarOnly
    }
  }

  @ViewBuilder
  var label: some View {
    if self != .other {
      Label(title, systemImage: iconName)
    }
  }

  var title: LocalizedStringKey {
    switch self {
    case .timeline:
      "tab.timeline"
    case .trending:
      "tab.trending"
    case .local:
      "tab.local"
    case .federated:
      "tab.federated"
    case .notifications:
      "tab.notifications"
    case .mentions:
      "tab.mentions"
    case .explore:
      "tab.explore"
    case .messages:
      "tab.messages"
    case .settings:
      "tab.settings"
    case .profile:
      "tab.profile"
    case .bookmarks:
      "accessibility.tabs.profile.picker.bookmarks"
    case .favorites:
      "accessibility.tabs.profile.picker.favorites"
    case .post:
      "menu.new-post"
    case .followedTags:
      "timeline.filter.tags"
    case .lists:
      "timeline.filter.lists"
    case .links:
      "explore.section.trending.links"
    case .other:
      ""
    }
  }

  var iconName: String {
    switch self {
    case .timeline:
      "rectangle.stack"
    case .trending:
      "chart.line.uptrend.xyaxis"
    case .local:
      "person.2"
    case .federated:
      "globe.americas"
    case .notifications:
      "bell"
    case .mentions:
      "at"
    case .explore:
      "magnifyingglass"
    case .messages:
      "tray"
    case .settings:
      "gear"
    case .profile:
      "person.crop.circle"
    case .bookmarks:
      "bookmark"
    case .favorites:
      "star"
    case .post:
      "square.and.pencil"
    case .followedTags:
      "tag"
    case .lists:
      "list.bullet"
    case .links:
      "newspaper"
    case .other:
      ""
    }
  }
}

@MainActor
enum SidebarSections: Int, Identifiable {
  case timeline, activities, account, app, loggedOutTabs, iosTabs, visionOSTabs
  
  nonisolated var id: Int {
    rawValue
  }
  
  static var macOrIpadOSSections: [SidebarSections] {
    [.timeline, .activities, .account, .app]
  }
  
  var title: String {
    switch self {
    case .timeline:
      "Timeline"
    case .activities:
      "Activities"
    case .account:
      "Account"
    case .app:
      "App"
    case .loggedOutTabs, .iosTabs, .visionOSTabs:
      ""
    }
  }
  
  var tabs: [AppTab] {
    switch self {
    case .timeline:
      return [.timeline, .trending, .local, .federated, .links, .explore]
    case .activities:
      return [.notifications, .mentions, .messages]
    case .account:
      return [.profile, .bookmarks, .favorites, .followedTags, .lists]
    case .app:
      return [.settings]
    case .loggedOutTabs:
      return [.timeline, .settings]
    case .iosTabs:
      return iOSTabs.shared.tabs
    case .visionOSTabs:
      return AppTab.visionOSTab()
    }
  }
}

@MainActor
@Observable
class iOSTabs {
  enum TabEntries: String {
    case first, second, third, fourth, fifth
  }

  class Storage {
    @AppStorage(TabEntries.first.rawValue) var firstTab = AppTab.timeline
    @AppStorage(TabEntries.second.rawValue) var secondTab = AppTab.notifications
    @AppStorage(TabEntries.third.rawValue) var thirdTab = AppTab.explore
    @AppStorage(TabEntries.fourth.rawValue) var fourthTab = AppTab.links
    @AppStorage(TabEntries.fifth.rawValue) var fifthTab = AppTab.profile
  }

  private let storage = Storage()
  public static let shared = iOSTabs()

  var tabs: [AppTab] {
    [firstTab, secondTab, thirdTab, fourthTab, fifthTab]
  }

  var firstTab: AppTab {
    didSet {
      storage.firstTab = firstTab
    }
  }

  var secondTab: AppTab {
    didSet {
      storage.secondTab = secondTab
    }
  }

  var thirdTab: AppTab {
    didSet {
      storage.thirdTab = thirdTab
    }
  }

  var fourthTab: AppTab {
    didSet {
      storage.fourthTab = fourthTab
    }
  }

  var fifthTab: AppTab {
    didSet {
      storage.fifthTab = fifthTab
    }
  }

  private init() {
    firstTab = storage.firstTab
    secondTab = storage.secondTab
    thirdTab = storage.thirdTab
    fourthTab = storage.fourthTab
    fifthTab = storage.fifthTab
  }
}
