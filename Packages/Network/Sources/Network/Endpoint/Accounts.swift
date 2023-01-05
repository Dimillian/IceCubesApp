import Foundation

public enum Accounts: Endpoint {
  case accounts(id: String)
  case favourites(sinceId: String?)
  case followedTags
  case featuredTags(id: String)
  case verifyCredentials
  case statuses(id: String,
                sinceId: String?,
                tag: String?,
                onlyMedia: Bool?,
                excludeReplies: Bool?,
                pinned: Bool?)
  case relationships(ids: [String])
  case follow(id: String)
  case unfollow(id: String)
  case familiarFollowers(withAccount: String)
  case suggestions
  case followers(id: String, maxId: String?)
  case following(id: String, maxId: String?)
  case lists(id: String)
  
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
    case .statuses(let id, _, _, _, _, _):
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
    case .following(let id, _):
      return "accounts/\(id)/following"
    case .followers(let id, _):
      return "accounts/\(id)/followers"
    case .lists(let id):
      return "accounts/\(id)/lists"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .statuses(_, let sinceId, let tag, let onlyMedia, let excludeReplies, let pinned):
      var params: [URLQueryItem] = []
      if let tag {
        params.append(.init(name: "tagged", value: tag))
      }
      if let sinceId {
        params.append(.init(name: "max_id", value: sinceId))
      }
      if let onlyMedia {
        params.append(.init(name: "only_media", value: onlyMedia ? "true" : "false"))
      }
      if let excludeReplies {
        params.append(.init(name: "exclude_replies", value: excludeReplies ? "true" : "fals"))
      }
      if let pinned {
        params.append(.init(name: "pinned", value: pinned ? "true" : "false"))
      }
      return params
    case let .relationships(ids):
      return ids.map {
        URLQueryItem(name: "id[]", value: $0)
      }
    case let .familiarFollowers(withAccount):
      return [.init(name: "id[]", value: withAccount)]
    case let .followers(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .following(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .favourites(sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    default:
      return nil
    }
  }
}
