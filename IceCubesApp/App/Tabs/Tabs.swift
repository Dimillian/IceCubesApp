import Account
import Explore
import Foundation
import Status
import SwiftUI
import DesignSystem

enum Tab: Int, Identifiable, Hashable {
  case timeline, notifications, mentions, explore, messages, settings, other
  case trending, federated, local
  case profile

  var id: Int {
    rawValue
  }

  static func loggedOutTab() -> [Tab] {
    [.timeline, .settings]
  }

  static func loggedInTabs() -> [Tab] {
    if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
      return [.timeline, .trending, .federated, .local, .notifications, .mentions, .explore, .messages, .settings]
    } else {
      return [.timeline, .notifications, .explore, .messages, .profile]
    }
  }

  @ViewBuilder
  func makeContentView(popToRootTab: Binding<Tab>) -> some View {
    switch self {
    case .timeline:
      TimelineTab(popToRootTab: popToRootTab)
    case .trending:
      TimelineTab(popToRootTab: popToRootTab, timeline: .trending)
    case .local:
      TimelineTab(popToRootTab: popToRootTab, timeline: .local)
    case .federated:
      TimelineTab(popToRootTab: popToRootTab, timeline: .federated)
    case .notifications:
      NotificationsTab(popToRootTab: popToRootTab, lockedType: nil)
    case .mentions:
      NotificationsTab(popToRootTab: popToRootTab, lockedType: .mention)
    case .explore:
      ExploreTab(popToRootTab: popToRootTab)
    case .messages:
      MessagesTab(popToRootTab: popToRootTab)
    case .settings:
      SettingsTabs(popToRootTab: popToRootTab)
    case .profile:
      ProfileTab(popToRootTab: popToRootTab)
    case .other:
      EmptyView()
    }
  }

  @ViewBuilder
  var label: some View {
    switch self {
    case .timeline:
      Label("tab.timeline", imageNamed: iconName)
    case .trending:
      Label("tab.trending", imageNamed: iconName)
    case .local:
      Label("tab.local", imageNamed: iconName)
    case .federated:
      Label("tab.federated", imageNamed: iconName)
    case .notifications:
      Label("tab.notifications", imageNamed: iconName)
    case .mentions:
      Label("tab.notifications", imageNamed: iconName)
    case .explore:
      Label("tab.explore", imageNamed: iconName)
    case .messages:
      Label("tab.messages", imageNamed: iconName)
    case .settings:
      Label("tab.settings", imageNamed: iconName)
    case .profile:
      Label("tab.profile", imageNamed: iconName)
    case .other:
      EmptyView()
    }
  }

  var iconName: String {
    switch self {
    case .timeline:
      return "rectangle.stack"
    case .trending:
      return "chart.line.uptrend.xyaxis"
    case .local:
      return "person.2"
    case .federated:
      return "globe.americas"
    case .notifications:
      return "bell"
    case .mentions:
      return "at"
    case .explore:
      return "magnifyingglass"
    case .messages:
      return "tray"
    case .settings:
      return "gear"
    case .profile:
      return "person.crop.circle"
    case .other:
      return ""
    }
  }
}
