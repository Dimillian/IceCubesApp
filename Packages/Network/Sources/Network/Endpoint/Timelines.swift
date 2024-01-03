import Foundation

public enum Timelines: Endpoint {
  case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool)
  case home(sinceId: String?, maxId: String?, minId: String?)
  case list(listId: String, sinceId: String?, maxId: String?, minId: String?)
  case hashtag(tag: String, additional: [String]?, maxId: String?, minId: String?)

  public func path() -> String {
    switch self {
    case .pub:
      "timelines/public"
    case .home:
      "timelines/home"
    case let .list(listId, _, _, _):
      "timelines/list/\(listId)"
    case let .hashtag(tag, _, _, _):
      "timelines/tag/\(tag)"
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
    case let .hashtag(_, additional, maxId, minId):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: minId) ?? []
      params.append(contentsOf: (additional ?? [])
        .map { URLQueryItem(name: "any[]", value: $0) })
      return params
    }
  }
}
