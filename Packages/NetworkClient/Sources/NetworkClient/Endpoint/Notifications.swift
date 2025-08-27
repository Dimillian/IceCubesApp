import Foundation
import Models

public enum Notifications: Endpoint {
  case notifications(
    minId: String?,
    maxId: String?,
    types: [String]?,
    limit: Int)
  case notificationsForAccount(accountId: String, maxId: String?)
  case notification(id: String)
  case policy
  case putPolicy(policy: Models.NotificationsPolicy)
  case requests
  case acceptRequests(ids: [String])
  case dismissRequests(ids: [String])
  case clear

  // V2 Grouped Notifications API
  case notificationsV2(
    sinceId: String?,
    maxId: String?,
    types: [String]?,
    excludeTypes: [String]?,
    accountId: String?,
    groupedTypes: [String]?,
    expandAccounts: String?)
  case notificationGroupV2(groupKey: String)
  case dismissNotificationGroupV2(groupKey: String)
  case notificationGroupAccountsV2(groupKey: String)
  case unreadCountV2(
    limit: Int,
    types: [String]?,
    excludeTypes: [String]?,
    accountId: String?,
    groupedTypes: [String]?)

  public func path() -> String {
    switch self {
    case .notifications, .notificationsForAccount:
      "notifications"
    case .notification(let id):
      "notifications/\(id)"
    case .policy, .putPolicy:
      "notifications/policy"
    case .requests:
      "notifications/requests"
    case .acceptRequests:
      "notifications/requests/accept"
    case .dismissRequests:
      "notifications/requests/dismiss"
    case .clear:
      "notifications/clear"
    case .notificationsV2:
      "notifications"
    case .notificationGroupV2(let groupKey):
      "notifications/\(groupKey)"
    case .dismissNotificationGroupV2(let groupKey):
      "notifications/\(groupKey)/dismiss"
    case .notificationGroupAccountsV2(let groupKey):
      "notifications/\(groupKey)/accounts"
    case .unreadCountV2:
      "notifications/unread_count"
    }
  }

  public var jsonValue: (any Encodable)? {
    switch self {
    case .putPolicy(let policy):
      return policy
    default:
      return nil
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .notificationsForAccount(let accountId, let maxId):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil) ?? []
      params.append(.init(name: "account_id", value: accountId))
      return params
    case .notifications(let mindId, let maxId, let types, let limit):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: mindId) ?? []
      params.append(.init(name: "limit", value: String(limit)))
      if let types {
        for type in types {
          params.append(.init(name: "exclude_types[]", value: type))
        }
      }
      return params
    case .acceptRequests(let ids), .dismissRequests(let ids):
      return ids.map { URLQueryItem(name: "id[]", value: $0) }
    case .notificationsV2(
      let sinceId, let maxId, let types, let excludeTypes, let accountId, let groupedTypes,
      let expandAccounts):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: nil) ?? []
      if let types {
        for type in types {
          params.append(.init(name: "types[]", value: type))
        }
      }
      if let excludeTypes {
        for type in excludeTypes {
          params.append(.init(name: "exclude_types[]", value: type))
        }
      }
      if let accountId {
        params.append(.init(name: "account_id", value: accountId))
      }
      if let groupedTypes {
        for type in groupedTypes {
          params.append(.init(name: "grouped_types[]", value: type))
        }
      }
      if let expandAccounts {
        params.append(.init(name: "expand_accounts", value: expandAccounts))
      }
      return params
    case .unreadCountV2(let limit, let types, let excludeTypes, let accountId, let groupedTypes):
      var params: [URLQueryItem] = []
      params.append(.init(name: "limit", value: String(limit)))
      if let types {
        for type in types {
          params.append(.init(name: "types[]", value: type))
        }
      }
      if let excludeTypes {
        for type in excludeTypes {
          params.append(.init(name: "exclude_types[]", value: type))
        }
      }
      if let accountId {
        params.append(.init(name: "account_id", value: accountId))
      }
      if let groupedTypes {
        for type in groupedTypes {
          params.append(.init(name: "grouped_types[]", value: type))
        }
      }
      return params
    default:
      return nil
    }
  }
}
