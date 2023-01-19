import Models

extension Models.Notification.NotificationType {
  func label() -> String {
    switch self {
    case .status:
      return "posted a status"
    case .mention:
      return "mentioned you"
    case .reblog:
      return "boosted"
    case .follow:
      return "followed you"
    case .follow_request:
      return "request to follow you"
    case .favourite:
      return "starred"
    case .poll:
      return "poll ended"
    case .update:
      return "edited a post"
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

  func menuTitle() -> String {
    switch self {
    case .status:
      return "Post"
    case .mention:
      return "Mentions"
    case .reblog:
      return "Boost"
    case .follow:
      return "Follow"
    case .follow_request:
      return "Follow Request"
    case .favourite:
      return "Favorite"
    case .poll:
      return "Poll"
    case .update:
      return "Post Edited"
    }
  }
}
