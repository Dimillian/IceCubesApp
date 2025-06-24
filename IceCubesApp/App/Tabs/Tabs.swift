import Account
import AppIntents
import DesignSystem
import Explore
import Foundation
import StatusKit
import SwiftUI
import Timeline
import Env

@MainActor
enum AppTab: Identifiable, Hashable, CaseIterable, Codable {
  case timeline, notifications, mentions, explore, messages, settings, other
  case trending, federated, local
  case profile
  case bookmarks
  case favorites
  case post
  case followedTags
  case lists
  case links
  case anyTimelineFilter(filter: TimelineFilter)
  
  nonisolated var id: Int {
    return switch self {
    case .timeline: 0
    case .notifications: 1
    case .mentions: 2
    case .explore: 3
    case .messages: 4
    case .settings: 5
    case .other: 6
    case .trending: 7
    case .federated: 8
    case .local: 9
    case .profile: 10
    case .bookmarks: 11
    case .favorites: 12
    case .post: 13
    case .followedTags: 14
    case .lists: 15
    case .links: 16
    case .anyTimelineFilter(let filter):
      filter.hashValue
    }
  }
  
  nonisolated static var allCases: [AppTab] {
    [.timeline,
      .notifications,
      .mentions,
      .explore,
      .messages,
      .settings,
      .other,
      .trending,
      .federated,
      .local,
      .profile,
      .bookmarks,
      .favorites,
      .post,
      .followedTags,
      .lists,
      .links]
  }
  
  init(with id: Int) {
    switch id {
    case 0:
      self = .timeline
    case 1:
      self = .notifications
    case 2:
      self = .mentions
    case 3:
      self = .explore
    case 4:
      self = .messages
    case 5:
      self = .settings
    case 6:
      self = .other
    case 7:
      self = .trending
    case 8:
      self = .federated
    case 9:
      self = .local
    case 10:
      self = .profile
    case 11:
      self = .bookmarks
    case 12:
      self = .favorites
    case 13:
      self = .post
    case 14:
      self = .followedTags
    case 15:
      self = .lists
    case 16:
      self = .links
    default:
      self = .other
    }
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
    case let .anyTimelineFilter(filter):
      TimelineTab(timeline: .constant(filter))
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
    case let .anyTimelineFilter(filter):
      filter.localizedTitle()
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
    case let .anyTimelineFilter(filter):
      filter.iconName()
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
  case timeline, activities, account, app, loggedOutTabs, iosTabs, visionOSTabs, lists, tags, localTimeline, tagGroup
  
  nonisolated var id: Int {
    rawValue
  }
  
  static var macOrIpadOSSections: [SidebarSections] {
    [.timeline, .activities, .account, .lists, .tags]
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
    case .lists:
      "Lists"
    case .tags:
      "Followed Hashtags"
    case .localTimeline:
      "Local Timelines"
    case .tagGroup:
      "Tag Groups"
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
      return [.profile, .bookmarks, .favorites]
    case .app:
      return [.settings]
    case .loggedOutTabs:
      return [.timeline, .settings]
    case .iosTabs:
      return iOSTabs.shared.tabs
    case .visionOSTabs:
      return AppTab.visionOSTab()
    case .lists:
      return CurrentAccount.shared.lists.map { .anyTimelineFilter(filter: .list(list: $0)) }
    case .tags:
      return CurrentAccount.shared.tags.map { .anyTimelineFilter(filter: .hashtag(tag: $0.name, accountId: nil)) }
    case .localTimeline, .tagGroup:
      return []
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
    @AppStorage(TabEntries.first.rawValue) var firstTab = AppTab.timeline.id
    @AppStorage(TabEntries.second.rawValue) var secondTab = AppTab.notifications.id
    @AppStorage(TabEntries.third.rawValue) var thirdTab = AppTab.explore.id
    @AppStorage(TabEntries.fourth.rawValue) var fourthTab = AppTab.links.id
    @AppStorage(TabEntries.fifth.rawValue) var fifthTab = AppTab.profile.id
  }

  private let storage = Storage()
  public static let shared = iOSTabs()

  var tabs: [AppTab] {
    [firstTab, secondTab, thirdTab, fourthTab, fifthTab]
  }

  var firstTab: AppTab {
    didSet {
      storage.firstTab = firstTab.id
    }
  }

  var secondTab: AppTab {
    didSet {
      storage.secondTab = secondTab.id
    }
  }

  var thirdTab: AppTab {
    didSet {
      storage.thirdTab = thirdTab.id
    }
  }

  var fourthTab: AppTab {
    didSet {
      storage.fourthTab = fourthTab.id
    }
  }

  var fifthTab: AppTab {
    didSet {
      storage.fifthTab = fifthTab.id
    }
  }

  private init() {
    firstTab = .init(with: storage.firstTab)
    secondTab = .init(with: storage.secondTab)
    thirdTab = .init(with: storage.thirdTab)
    fourthTab = .init(with: storage.fourthTab)
    fifthTab = .init(with: storage.fifthTab)
  }
}
