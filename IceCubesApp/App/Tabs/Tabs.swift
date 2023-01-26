import Account
import Explore
import Foundation
import Status
import SwiftUI

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
      Label("tab.timeline", systemImage: iconName)
    case .trending:
      Label("tab.trending", systemImage: iconName)
    case .local:
      Label("tab.local", systemImage: iconName)
    case .federated:
      Label("tab.federated", systemImage: iconName)
    case .notifications:
      Label("tab.notifications", systemImage: iconName)
    case .mentions:
      Label("tab.notifications", systemImage: iconName)
    case .explore:
      Label("tab.explore", systemImage: iconName)
    case .messages:
      Label("tab.messages", systemImage: iconName)
    case .settings:
      Label("tab.settings", systemImage: iconName)
    case .profile:
      Label("tab.profile", systemImage: iconName)
    case .other:
      EmptyView()
    }
  }

  var iconName: String {
    switch self {
    case .timeline:
      return "rectangle.on.rectangle"
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
