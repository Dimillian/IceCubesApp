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
  
  public var title: String {
    switch self {
    case .pub:
      return "Everyone"
    case .unlisted:
      return "Unlisted"
    case .priv:
      return "Followers"
    case .direct:
      return "Private Mention"
    }
  }
}
