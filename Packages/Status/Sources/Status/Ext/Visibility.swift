import Models

public extension Visibility {
  static var supportDefault: [Visibility] {
    [.pub, .priv, .unlisted]
  }

  var iconName: String {
    switch self {
    case .pub:
      return "globe.americas"
    case .unlisted:
      return "lock.open"
    case .priv:
      return "lock"
    case .direct:
      return "tray.full"
    }
  }

  var title: String {
    switch self {
    case .pub:
      return "Everyone"
    case .unlisted:
      return "Unlisted"
    case .priv:
      return "Followers"
    case .direct:
      return "Private"
    }
  }
}
