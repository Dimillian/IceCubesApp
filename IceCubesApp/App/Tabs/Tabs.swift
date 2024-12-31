import Account
import AppIntents
import DesignSystem
import Explore
import Foundation
import StatusKit
import SwiftUI

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
  func makeContentView(selectedTab: Binding<AppTab>) -> some View {
    switch self {
    case .timeline:
      TimelineTab()
    case .trending:
      TimelineTab(timeline: .trending)
    case .local:
      TimelineTab(timeline: .local)
    case .federated:
      TimelineTab(timeline: .federated)
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
@Observable
class SidebarTabs {
  struct SidedebarTab: Hashable, Codable {
    let tab: AppTab
    var enabled: Bool
  }

  class Storage {
    @AppStorage("sidebar_tabs") var tabs: [SidedebarTab] = [
      .init(tab: .timeline, enabled: true),
      .init(tab: .trending, enabled: true),
      .init(tab: .federated, enabled: true),
      .init(tab: .local, enabled: true),
      .init(tab: .notifications, enabled: true),
      .init(tab: .mentions, enabled: true),
      .init(tab: .messages, enabled: true),
      .init(tab: .explore, enabled: true),
      .init(tab: .bookmarks, enabled: true),
      .init(tab: .favorites, enabled: true),
      .init(tab: .followedTags, enabled: true),
      .init(tab: .lists, enabled: true),
      .init(tab: .links, enabled: true),

      .init(tab: .settings, enabled: true),
      .init(tab: .profile, enabled: true),
    ]
  }

  private let storage = Storage()
  public static let shared = SidebarTabs()

  var tabs: [SidedebarTab] {
    didSet {
      storage.tabs = tabs
    }
  }

  func isEnabled(_ tab: AppTab) -> Bool {
    tabs.first(where: { $0.tab.id == tab.id })?.enabled == true
  }

  private init() {
    tabs = storage.tabs
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
