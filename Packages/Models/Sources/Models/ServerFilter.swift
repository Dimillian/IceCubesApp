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
    expiresAt != nil
  }

  public func isExpired() -> Bool {
    if let expiresAtDate = expiresAt?.asDate {
      expiresAtDate < Date()
    } else {
      false
    }
  }
}

extension ServerFilter.Context {
  public var iconName: String {
    switch self {
    case .home:
      "rectangle.stack"
    case .notifications:
      "bell"
    case .public:
      "globe.americas"
    case .thread:
      "bubble.left.and.bubble.right"
    case .account:
      "person.crop.circle"
    }
  }

  public var name: String {
    switch self {
    case .home:
      NSLocalizedString("filter.contexts.home", comment: "")
    case .notifications:
      NSLocalizedString("filter.contexts.notifications", comment: "")
    case .public:
      NSLocalizedString("filter.contexts.public", comment: "")
    case .thread:
      NSLocalizedString("filter.contexts.conversations", comment: "")
    case .account:
      NSLocalizedString("filter.contexts.profiles", comment: "")
    }
  }
}

extension ServerFilter.Action {
  public var label: String {
    switch self {
    case .warn:
      NSLocalizedString("filter.action.warning", comment: "")
    case .hide:
      NSLocalizedString("filter.action.hide", comment: "")
    }
  }
}
