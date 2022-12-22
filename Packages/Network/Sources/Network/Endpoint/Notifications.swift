import Foundation

public enum Notifications: Endpoint {
  case notifications(maxId: String?, onlyMentions: Bool)
  
  public func path() -> String {
    switch self {
    case .notifications:
      return "notifications"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .notifications(let maxId, let onlyMentions):
      var params: [URLQueryItem] = []
      if onlyMentions {
        params.append(.init(name: "types[]", value: "mention"))
      }
      if let maxId {
        params.append(.init(name: "max_id", value: maxId))
      }
      return params
    }
  }
}
