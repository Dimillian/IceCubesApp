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
      return [.timeline, .notifications, .explore, .messages, .settings]
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
    case .other, .profile:
      EmptyView()
    }
  }

  @ViewBuilder
  var label: some View {
    switch self {
    case .timeline:
      Label("Timeline", systemImage: iconName)
    case .trending:
      Label("Trending", systemImage: iconName)
    case .local:
      Label("Local", systemImage: iconName)
    case .federated:
      Label("Federated", systemImage: iconName)
    case .notifications:
      Label("Notifications", systemImage: iconName)
    case .mentions:
      Label("Notifications", systemImage: iconName)
    case .explore:
      Label("Explore", systemImage: iconName)
    case .messages:
      Label("Messages", systemImage: iconName)
    case .settings:
      Label("Settings", systemImage: iconName)
    case .other, .profile:
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
    case .other, .profile:
      return ""
    }
  }
}
