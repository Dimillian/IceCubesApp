import Foundation

public struct ServerFilter: Codable, Identifiable, Hashable, Sendable {
  public struct Keyword: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let keyword: String
    public let wholeWord: Bool
  }

  public enum Context: String, Codable, CaseIterable, Sendable {
    case home, notifications, `public`, thread, account
  }

  public enum Action: String, Codable, CaseIterable, Sendable {
    case warn, hide
  }

  public let id: String
  public let title: String
  public let keywords: [Keyword]
  public let filterAction: Action
  public let context: [Context]
  public let expiresIn: Int?
  public let expiresAt: ServerDate?

  public func hasExpiry() -> Bool {
    return expiresAt != nil
  }

  public func isExpired() -> Bool {
    if let expiresAtDate = expiresAt?.asDate {
      return expiresAtDate < Date()
    } else {
      return false
    }
  }
}

public extension ServerFilter.Context {
  var iconName: String {
    switch self {
    case .home:
      return "rectangle.stack"
    case .notifications:
      return "bell"
    case .public:
      return "globe.americas"
    case .thread:
      return "bubble.left.and.bubble.right"
    case .account:
      return "person.crop.circle"
    }
  }

  var name: String {
    switch self {
    case .home:
      return NSLocalizedString("filter.contexts.home", comment: "")
    case .notifications:
      return NSLocalizedString("filter.contexts.notifications", comment: "")
    case .public:
      return NSLocalizedString("filter.contexts.public", comment: "")
    case .thread:
      return NSLocalizedString("filter.contexts.conversations", comment: "")
    case .account:
      return NSLocalizedString("filter.contexts.profiles", comment: "")
    }
  }
}

public extension ServerFilter.Action {
  var label: String {
    switch self {
    case .warn:
      return NSLocalizedString("filter.action.warning", comment: "")
    case .hide:
      return NSLocalizedString("filter.action.hide", comment: "")
    }
  }
}
