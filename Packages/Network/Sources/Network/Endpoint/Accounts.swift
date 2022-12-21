import Foundation

public enum Accounts: Endpoint {
  case accounts(id: String)
  case favourites(sinceId: String?)
  case verifyCredentials
  case statuses(id: String, sinceId: String?)
  case relationships(id: String)
  case follow(id: String)
  case unfollow(id: String)
  
  public func path() -> String {
    switch self {
    case .accounts(let id):
      return "accounts/\(id)"
    case .favourites:
      return "favourites"
    case .verifyCredentials:
      return "accounts/verify_credentials"
    case .statuses(let id, _):
      return "accounts/\(id)/statuses"
    case .relationships:
      return "accounts/relationships"
    case .follow(let id):
      return "accounts/\(id)/follow"
    case .unfollow(let id):
      return "accounts/\(id)/unfollow"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .statuses(_, let sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    case .favourites(let sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    case let .relationships(id):
      return [.init(name: "id", value: id)]
    default:
      return nil
    }
  }
}
