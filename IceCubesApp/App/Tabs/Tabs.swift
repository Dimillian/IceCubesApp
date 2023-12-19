import Account
import DesignSystem
import Explore
import Foundation
import Status
import SwiftUI

@MainActor
enum Tab: Int, Identifiable, Hashable {
  case timeline, notifications, mentions, explore, messages, settings, other
  case trending, federated, local
  case profile

  nonisolated var id: Int {
    rawValue
  }

  static func loggedOutTab() -> [Tab] {
    [.timeline, .settings]
  }

  static func loggedInTabs() -> [Tab] {
    if UIDevice.current.userInterfaceIdiom == .pad ||
        UIDevice.current.userInterfaceIdiom == .mac {
      [.timeline, .trending, .federated, .local, .notifications, .mentions, .explore, .messages, .settings]
    } else if  UIDevice.current.userInterfaceIdiom == .vision {
      [.profile, .timeline, .trending, .federated, .local, .notifications, .mentions, .explore, .messages, .settings]
    } else {
      [.timeline, .notifications, .explore, .messages, .profile]
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
      SettingsTabs(popToRootTab: popToRootTab, isModal: false)
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
    case .other:
      ""
    }
  }
}
