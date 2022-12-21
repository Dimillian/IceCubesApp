import Foundation

public enum Statuses: Endpoint {
  case status(id: String)
  case context(id: String)
  case favourite(id: String)
  case unfavourite(id: String)
  case reblog(id: String)
  case unreblog(id: String)
  
  public func path() -> String {
    switch self {
    case .status(let id):
      return "statuses/\(id)"
    case .context(let id):
      return "statuses/\(id)/context"
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
