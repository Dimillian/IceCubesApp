import Foundation

public enum Trends: Endpoint {
  case tags
  case statuses(offset: Int?)
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
    case let .statuses(offset):
      if let offset {
        return [.init(name: "offset", value: String(offset))]
      }
      return nil
    default:
      return nil
    }
  }
}
