import Foundation

public enum Timelines: Endpoint {
  case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool)
  case home(sinceId: String?, maxId: String?, minId: String?)
  case list(listId: String, sinceId: String?, maxId: String?, minId: String?)
  case hashtag(tag: String, maxId: String?)

  public func path() -> String {
    switch self {
    case .pub:
      return "timelines/public"
    case .home:
      return "timelines/home"
    case let .list(listId, _, _, _):
      return "timelines/list/\(listId)"
    case let .hashtag(tag, _):
      return "timelines/tag/\(tag)"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .pub(sinceId, maxId, minId, local):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
      params.append(.init(name: "local", value: local ? "true" : "false"))
      return params
    case let .home(sinceId, maxId, mindId):
      return makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: mindId)
    case let .list(_, sinceId, maxId, mindId):
      return makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: mindId)
    case let .hashtag(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    }
  }
}
