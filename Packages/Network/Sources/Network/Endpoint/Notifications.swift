import Foundation
import Models

public enum Notifications: Endpoint {
  case notifications(minId: String?,
                     maxId: String?,
                     types: [String]?,
                     limit: Int)
  case notificationsForAccount(accountId: String, maxId: String?)
  case notification(id: String)
  case policy
  case putPolicy(policy: Models.NotificationsPolicy)
  case requests
  case acceptRequest(id: String)
  case dismissRequest(id: String)
  case clear

  public func path() -> String {
    switch self {
    case .notifications, .notificationsForAccount:
      "notifications"
    case let .notification(id):
      "notifications/\(id)"
    case .policy, .putPolicy:
      "notifications/policy"
    case .requests:
      "notifications/requests"
    case let .acceptRequest(id):
      "notifications/requests/\(id)/accept"
    case let .dismissRequest(id):
      "notifications/requests/\(id)/dismiss"
    case .clear:
      "notifications/clear"
    }
  }

  public var jsonValue: (any Encodable)? {
    switch self {
    case let .putPolicy(policy):
      return policy
    default:
      return nil
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .notificationsForAccount(accountId, maxId):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil) ?? []
      params.append(.init(name: "account_id", value: accountId))
      return params
    case let .notifications(mindId, maxId, types, limit):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: mindId) ?? []
      params.append(.init(name: "limit", value: String(limit)))
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
