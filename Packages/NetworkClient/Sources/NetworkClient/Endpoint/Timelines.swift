import Foundation

public enum Timelines: Endpoint {
  case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool, limit: Int?)
  case home(sinceId: String?, maxId: String?, minId: String?, limit: Int?)
  case list(listId: String, sinceId: String?, maxId: String?, minId: String?)
  case hashtag(tag: String, additional: [String]?, maxId: String?, minId: String?)
  case link(url: URL, sinceId: String?, maxId: String?, minId: String?)

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
    case .link:
      "timelines/link"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .pub(sinceId, maxId, minId, local, limit):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
      params.append(.init(name: "local", value: local ? "true" : "false"))
      if let limit {
        params.append(.init(name: "limit", value: String(limit)))
      }
      return params
    case let .home(sinceId, maxId, minId, limit):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
      if let limit {
        params.append(.init(name: "limit", value: String(limit)))
      }
      return params
    case let .list(_, sinceId, maxId, minId):
      return makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId)
    case let .hashtag(_, additional, maxId, minId):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: minId) ?? []
      params.append(
        contentsOf: (additional ?? [])
          .map { URLQueryItem(name: "any[]", value: $0) })
      return params
    case let .link(url, sinceId, maxId, minId):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
      params.append(.init(name: "url", value: url.absoluteString))
      return params
    }
  }
}
