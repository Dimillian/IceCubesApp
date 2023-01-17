import Foundation

public enum Media: Endpoint {
  case medias
  case media(id: String, description: String?)

  public func path() -> String {
    switch self {
    case .medias:
      return "media"
    case let .media(id, _):
      return "media/\(id)"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .media(_, description):
      if let description {
        return [.init(name: "description", value: description)]
      }
      return nil
    default:
      return nil
    }
  }
}
