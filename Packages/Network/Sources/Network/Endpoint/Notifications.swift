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
    minId: String?,
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
    case let .notification(id):
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
    case let .notificationGroupV2(groupKey):
      "notifications/\(groupKey)"
    case let .dismissNotificationGroupV2(groupKey):
      "notifications/\(groupKey)/dismiss"
    case let .notificationGroupAccountsV2(groupKey):
      "notifications/\(groupKey)/accounts"
    case .unreadCountV2:
      "notifications/unread_count"
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
    case let .acceptRequests(ids), let .dismissRequests(ids):
      return ids.map { URLQueryItem(name: "id[]", value: $0) }
    case let .notificationsV2(minId, maxId, types, excludeTypes, accountId, groupedTypes, expandAccounts):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: minId) ?? []
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
    case let .unreadCountV2(limit, types, excludeTypes, accountId, groupedTypes):
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
