import Foundation

public enum Tags: Endpoint {
  case tag(id: String)
  case follow(id: String)
  case unfollow(id: String)
  
  public func path() -> String {
    switch self {
    case .tag(let id):
      return "tags/\(id)/"
    case .follow(let id):
      return "tags/\(id)/follow"
    case .unfollow(let id):
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
