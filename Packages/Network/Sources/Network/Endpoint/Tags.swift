import Foundation

public enum Tags: Endpoint {
  case tag(id: String)
  case follow(id: String)
  case unfollow(id: String)

  public func path() -> String {
    switch self {
    case let .tag(id):
      return "tags/\(id)/"
    case let .follow(id):
      return "tags/\(id)/follow"
    case let .unfollow(id):
      return "tags/\(id)/unfollow"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    default:
      return nil
    }
  }
}
