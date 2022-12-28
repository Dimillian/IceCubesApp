import Foundation

public enum Timelines: Endpoint {
  case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool)
  case home(sinceId: String?, maxId: String?, minId: String?)
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
    case .pub(let sinceId, let maxId, let minId, let local):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
      params.append(.init(name: "local", value: local ? "true" : "false"))
      return params
    case .home(let sinceId, let maxId, let mindId):
      return makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: mindId)
    case let .hashtag(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    }
  }
}
