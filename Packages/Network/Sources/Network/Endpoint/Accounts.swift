import Foundation

public enum Accounts: Endpoint {
  case accounts(id: String)
  case favourites
  case followedTags
  case featuredTags(id: String)
  case verifyCredentials
  case statuses(id: String, sinceId: String?, tag: String?)
  case relationships(ids: [String])
  case follow(id: String)
  case unfollow(id: String)
  case familiarFollowers(withAccount: String)
  case suggestions
  
  public func path() -> String {
    switch self {
    case .accounts(let id):
      return "accounts/\(id)"
    case .favourites:
      return "favourites"
    case .followedTags:
      return "followed_tags"
    case .featuredTags(let id):
      return "accounts/\(id)/featured_tags"
    case .verifyCredentials:
      return "accounts/verify_credentials"
    case .statuses(let id, _, _):
      return "accounts/\(id)/statuses"
    case .relationships:
      return "accounts/relationships"
    case .follow(let id):
      return "accounts/\(id)/follow"
    case .unfollow(let id):
      return "accounts/\(id)/unfollow"
    case .familiarFollowers:
      return "accounts/familiar_followers"
    case .suggestions:
      return "suggestions"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .statuses(_, let sinceId, let tag):
      var params: [URLQueryItem] = []
      if let tag {
        params.append(.init(name: "tagged", value: tag))
      }
      if let sinceId {
        params.append(.init(name: "max_id", value: sinceId))
      }
      return params
    case let .relationships(ids):
      return ids.map {
        URLQueryItem(name: "id[]", value: $0)
      }
    case let .familiarFollowers(withAccount):
      return [.init(name: "id[]", value: withAccount)]
    default:
      return nil
    }
  }
}
