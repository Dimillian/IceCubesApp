import Foundation

public enum Timelines: Endpoint {
  case pub(sinceId: String?, maxId: String?)
  case home(sinceId: String?, maxId: String?)
  case hashtag(tag: String, maxId: String?)
  
  public func path() -> String {
    switch self {
    case .pub:
      return "timelines/public"
    case .home:
      return "timelines/home"
    case let .hashtag(tag, _):
      return "timelines/tag/\(tag)"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .pub(let sinceId, let maxId):
      return makePaginationParam(sinceId: sinceId, maxId: maxId)
    case .home(let sinceId, let maxId):
      return makePaginationParam(sinceId: sinceId, maxId: maxId)
    case let .hashtag(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId)
    }
  }
}
