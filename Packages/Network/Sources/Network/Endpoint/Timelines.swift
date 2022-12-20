import Foundation

public enum Timelines: Endpoint {
  case pub(sinceId: String?)
  case home(sinceId: String?)
  case hashtag(tag: String, sinceId: String?)
  
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
    case .pub(let sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    case .home(let sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    case let .hashtag(_, sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    }
  }
}
