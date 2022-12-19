import Foundation

public enum Notifications: Endpoint {
  case notifications(maxId: String?)
  
  public func path() -> String {
    switch self {
    case .notifications:
      return "notifications"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .notifications(let maxId):
      guard let maxId else { return nil }
      return [.init(name: "max_id", value: maxId)]
    }
  }
}
