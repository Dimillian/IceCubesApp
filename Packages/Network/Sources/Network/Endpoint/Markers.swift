import Foundation

public enum Markers: Endpoint {
  case markers
  case markNotifications(lastReadId: String)
  case markHome(lastReadId: String)

  public func path() -> String {
    "markers"
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .markers:
      [URLQueryItem(name: "timeline[]", value: "home"),
       URLQueryItem(name: "timeline[]", value: "notifications")]
    case let .markNotifications(lastReadId):
      [URLQueryItem(name: "notifications[last_read_id]", value: lastReadId)]
    case let .markHome(lastReadId):
      [URLQueryItem(name: "home[last_read_id]", value: lastReadId)]
    }
  }
}
