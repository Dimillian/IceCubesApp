import Foundation

public enum Timeline: Endpoint {
  case pub(sinceId: String?)
  
  public func path() -> String {
    switch self {
    case .pub:
      return "timelines/public"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .pub(let sinceId):
      return [.init(name: "max_id", value: sinceId)]
    }
  }
}
