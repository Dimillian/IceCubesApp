import Foundation
import Models

public enum Lists: Endpoint {
  case lists
  case list(id: String)
  case createList(title: String, repliesPolicy: List.RepliesPolicy, exclusive: Bool)
  case updateList(id: String, title: String, repliesPolicy: List.RepliesPolicy, exclusive: Bool)
  case accounts(listId: String)
  case updateAccounts(listId: String, accounts: [String])

  public func path() -> String {
    switch self {
    case .lists, .createList:
      "lists"
    case let .list(id), let .updateList(id, _, _, _):
      "lists/\(id)"
    case let .accounts(listId):
      "lists/\(listId)/accounts"
    case let .updateAccounts(listId, _):
      "lists/\(listId)/accounts"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .accounts:
      return [.init(name: "limit", value: String(0))]
    case let .createList(title, repliesPolicy, exclusive),
         let .updateList(_, title, repliesPolicy, exclusive):
      return [.init(name: "title", value: title),
              .init(name: "replies_policy", value: repliesPolicy.rawValue),
              .init(name: "exclusive", value: exclusive ? "true" : "false")]
    case let .updateAccounts(_, accounts):
      var params: [URLQueryItem] = []
      for account in accounts {
        params.append(.init(name: "account_ids[]", value: account))
      }
      return params
    default:
      return nil
    }
  }
}
