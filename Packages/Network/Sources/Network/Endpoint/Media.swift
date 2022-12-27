import Foundation

public enum Media: Endpoint {
  case medias
  case media(id: String)
  
  public func path() -> String {
    switch self {
    case .medias:
      return "media"
    case let .media(id):
      return "media/\(id)"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    return nil
  }
}
