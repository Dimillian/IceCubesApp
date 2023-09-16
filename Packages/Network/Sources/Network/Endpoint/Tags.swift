import Foundation

public enum Tags: Endpoint {
  case tag(id: String)
  case follow(id: String)
  case unfollow(id: String)

  public func path() -> String {
    switch self {
    case let .tag(id):
      "tags/\(id)/"
    case let .follow(id):
      "tags/\(id)/follow"
    case let .unfollow(id):
      "tags/\(id)/unfollow"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    default:
      nil
    }
  }
}
