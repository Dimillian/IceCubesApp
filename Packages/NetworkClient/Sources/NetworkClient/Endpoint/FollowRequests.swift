import Foundation

public enum FollowRequests: Endpoint {
  case list
  case accept(id: String)
  case reject(id: String)

  public func path() -> String {
    switch self {
    case .list:
      "follow_requests"
    case let .accept(id):
      "follow_requests/\(id)/authorize"
    case let .reject(id):
      "follow_requests/\(id)/reject"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
