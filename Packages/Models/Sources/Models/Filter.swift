import Foundation

public struct Filtered: Codable {
  public let filter: Filter
  public let keywordMatches: [String]?
}

public struct Filter: Codable, Identifiable {
  public enum Action: String, Codable {
    case warn, hide
  }
  
  public enum Context: String, Codable {
    case home, notifications, account, thread
    case pub = "public"
  }
  
  public let id: String
  public let title: String
  public let context: [String]
  public let filterAction: Action
}
