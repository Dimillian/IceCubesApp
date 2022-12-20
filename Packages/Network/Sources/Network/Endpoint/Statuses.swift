import Foundation

public enum Statuses: Endpoint {
  case favourite(id: String)
  case unfavourite(id: String)
  
  public func path() -> String {
    switch self {
    case .favourite(let id):
      return "statuses/\(id)/favourite"
    case .unfavourite(let id):
      return "statuses/\(id)/unfavourite"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    default:
      return nil
    }
  }
}
