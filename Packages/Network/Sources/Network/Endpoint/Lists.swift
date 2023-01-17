import Foundation

public enum Lists: Endpoint {
  case lists
  case list(id: String)
  case createList(title: String)
  case accounts(listId: String)
  case updateAccounts(listId: String, accounts: [String])

  public func path() -> String {
    switch self {
    case .lists, .createList:
      return "lists"
    case let .list(id):
      return "lists/\(id)"
    case let .accounts(listId):
      return "lists/\(listId)/accounts"
    case let .updateAccounts(listId, _):
      return "lists/\(listId)/accounts"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .accounts:
      return [.init(name: "limit", value: String(0))]
    case let .createList(title):
      return [.init(name: "title", value: title)]
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
