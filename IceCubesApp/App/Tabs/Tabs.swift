import Foundation
import Status
import Account
import Explore
import SwiftUI

enum Tab: Int, Identifiable, Hashable {
  case timeline, notifications, explore, messages, settings, other
  
  var id: Int {
    rawValue
  }
  
  static func loggedOutTab() -> [Tab] {
    [.timeline, .settings]
  }
  
  static func loggedInTabs() -> [Tab] {
    [.timeline, .notifications, .explore, .messages, .settings]
  }
  
  @ViewBuilder
  func makeContentView(popToRootTab: Binding<Tab>) -> some View {
    switch self {
    case .timeline:
      TimelineTab(popToRootTab: popToRootTab)
    case .notifications:
      NotificationsTab(popToRootTab: popToRootTab)
    case .explore:
      ExploreTab(popToRootTab: popToRootTab)
    case .messages:
      MessagesTab(popToRootTab: popToRootTab)
    case .settings:
      SettingsTabs(popToRootTab: popToRootTab)
    case .other:
      EmptyView()
    }
  }
  
  @ViewBuilder
  var label: some View {
    switch self {
    case .timeline:
      Label("Timeline", systemImage: "rectangle.on.rectangle")
    case .notifications:
      Label("Notifications", systemImage: "bell")
    case .explore:
      Label("Explore", systemImage: "magnifyingglass")
    case .messages:
      Label("Messages", systemImage: "tray")
    case .settings:
      Label("Settings", systemImage: "gear")
    case .other:
      EmptyView()
    }
  }
}

