import Foundation

public enum Trends: Endpoint {
  case tags
  case statuses(offset: Int?)
  case links(offset: Int?)

  public func path() -> String {
    switch self {
    case .tags:
      "trends/tags"
    case .statuses:
      "trends/statuses"
    case .links:
      "trends/links"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .statuses(offset), let .links(offset):
      if let offset {
        return [.init(name: "offset", value: String(offset))]
      }
      return nil
    default:
      return nil
    }
  }
}
