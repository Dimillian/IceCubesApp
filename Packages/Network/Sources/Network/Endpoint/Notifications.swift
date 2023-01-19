import Foundation

public enum Notifications: Endpoint {
  case notifications(sinceId: String?,
                     maxId: String?,
                     types: [String]?)
  case clear

  public func path() -> String {
    switch self {
    case .notifications:
      return "notifications"
    case .clear:
      return "notifications/clear"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .notifications(sinceId, maxId, types):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: nil) ?? []
      if let types {
        for type in types {
          params.append(.init(name: "exclude_types[]", value: type))
        }
      }
      return params
    default:
      return nil
    }
  }
}
