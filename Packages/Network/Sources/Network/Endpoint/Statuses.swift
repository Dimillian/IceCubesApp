import Foundation

public enum Statuses: Endpoint {
  case favourite(id: String)
  case unfavourite(id: String)
  case reblog(id: String)
  case unreblog(id: String)
  
  public func path() -> String {
    switch self {
    case .favourite(let id):
      return "statuses/\(id)/favourite"
    case .unfavourite(let id):
      return "statuses/\(id)/unfavourite"
    case .reblog(let id):
      return "statuses/\(id)/reblog"
    case .unreblog(let id):
      return "statuses/\(id)/unreblog"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    default:
      return nil
    }
  }
}
