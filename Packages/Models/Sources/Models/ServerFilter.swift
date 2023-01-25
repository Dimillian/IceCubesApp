import Foundation

public struct ServerFilter: Codable, Identifiable, Hashable {
  public struct Keyword: Codable, Identifiable, Hashable {
    public let id: String
    public let keyword: String
    public let wholeWord: Bool
  }
  
  public enum Context: String, Codable, CaseIterable {
    case home, notifications, `public`, thread, account
  }
  
  public enum Action: String, Codable, CaseIterable {
    case warn, hide
  }
  
  public let id: String
  public let title: String
  public let keywords: [Keyword]
  public let filterAction: Action
  public let context: [Context]
  public let expireIn: Int?
}

extension ServerFilter.Context {
  public var iconName: String {
    switch self {
    case .home:
      return "rectangle.on.rectangle"
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
  
  public var name: String {
    switch self {
    case .home:
      return "Home and lists"
    case .notifications:
      return "Notifications"
    case .public:
      return "Public timelines"
    case .thread:
      return "Conversations"
    case .account:
      return "Profiles"
    }
  }
}

extension ServerFilter.Action {
  public var label: String {
    switch self {
    case .warn:
      return "Hide with a warning"
    case .hide:
      return "Hide completely"
    }
  }
}
