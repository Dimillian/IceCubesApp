import Foundation

public enum Media: Endpoint {
  case medias
  case media(id: String, json: MediaDescriptionData?)

  public func path() -> String {
    switch self {
    case .medias:
      "media"
    case let .media(id, _):
      "media/\(id)"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    nil
  }

  public var jsonValue: Encodable? {
    switch self {
    case let .media(_, json):
      if let json {
        return json
      }
      return nil
    default:
      return nil
    }
  }
}

public struct MediaDescriptionData: Encodable, Sendable {
  public let description: String?

  public init(description: String?) {
    self.description = description
  }
}
