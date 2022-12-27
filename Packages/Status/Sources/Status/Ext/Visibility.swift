import Models

extension Visibility {
  public var iconName: String {
    switch self {
    case .pub:
      return "globe.americas"
    case .unlisted:
      return "lock.open"
    case .priv:
      return "lock"
    case .direct:
      return "at.circle"
    }
  }
}
