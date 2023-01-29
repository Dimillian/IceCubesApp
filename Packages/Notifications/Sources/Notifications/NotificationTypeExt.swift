import Models
import SwiftUI

extension Models.Notification.NotificationType {
  func label(count: Int) -> LocalizedStringKey {
    switch self {
    case .status:
      return "notifications.label.status"
    case .mention:
      return ""
    case .reblog:
      return "notifications.label.reblog \(count)"
    case .follow:
      return "notifications.label.follow \(count)"
    case .follow_request:
      return "notifications.label.follow-request"
    case .favourite:
      return "notifications.label.favorite \(count)"
    case .poll:
      return "notifications.label.poll"
    case .update:
      return "notifications.label.update"
    }
  }

  func iconName() -> String {
    switch self {
    case .status:
      return "pencil"
    case .mention:
      return "at"
    case .reblog:
      return "arrow.left.arrow.right.circle.fill"
    case .follow, .follow_request:
      return "person.fill.badge.plus"
    case .favourite:
      return "star.fill"
    case .poll:
      return "chart.bar.fill"
    case .update:
      return "pencil.line"
    }
  }

  func menuTitle() -> LocalizedStringKey {
    switch self {
    case .status:
      return "notifications.menu-title.status"
    case .mention:
      return "notifications.menu-title.mention"
    case .reblog:
      return "notifications.menu-title.reblog"
    case .follow:
      return "notifications.menu-title.follow"
    case .follow_request:
      return "notifications.menu-title.follow-request"
    case .favourite:
      return "notifications.menu-title.favorite"
    case .poll:
      return "notifications.menu-title.poll"
    case .update:
      return "notifications.menu-title.update"
    }
  }
}
