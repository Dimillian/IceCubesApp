import Foundation

public enum Trends: Endpoint {
  case tags
  case statuses
  case links
  
  public func path() -> String {
    switch self {
    case .tags:
      return "trends/tags"
    case .statuses:
      return "trends/statuses"
    case .links:
      return "trends/links"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    default:
      return nil
    }
  }
}
