import DesignSystem
import Models
import SwiftUI

extension Models.Notification.NotificationType {
  public func label(count: Int) -> LocalizedStringKey {
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

  public func notificationKey() -> String {
    switch self {
    case .status:
      return "notifications.label.status.push"
    case .mention:
      return ""
    case .reblog:
      return "notifications.label.reblog.push"
    case .follow:
      return "notifications.label.follow.push"
    case .follow_request:
      return "notifications.label.follow-request.push"
    case .favourite:
      return "notifications.label.favorite.push"
    case .poll:
      return "notifications.label.poll.push"
    case .update:
      return "notifications.label.update.push"
    }
  }

  func icon(isPrivate: Bool) -> Image {
    if isPrivate {
      return Image(systemName:"tray.fill")
    }
    switch self {
    case .status:
      return Image(systemName:"pencil")
    case .mention:
      return Image(systemName:"at")
    case .reblog:
      return Image("Rocket.Fill")
    case .follow, .follow_request:
      return Image(systemName:"person.fill.badge.plus")
    case .favourite:
      return Image(systemName:"star.fill")
    case .poll:
      return Image(systemName:"chart.bar.fill")
    case .update:
      return Image(systemName:"pencil.line")
    }
  }

  func tintColor(isPrivate: Bool) -> Color {
    if isPrivate {
      return Color.orange.opacity(0.80)
    }
    switch self {
    case .status, .mention, .update, .poll:
      return Theme.shared.tintColor.opacity(0.80)
    case .reblog:
      return Color.teal.opacity(0.80)
    case .follow, .follow_request:
      return Color.cyan.opacity(0.80)
    case .favourite:
      return Color.yellow.opacity(0.80)
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
