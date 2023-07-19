import Foundation

public enum Media: Endpoint {
  case medias
  case media(id: String, json: MediaDescriptionData)

  public func path() -> String {
    switch self {
    case .medias:
      return "media"
    case let .media(id, _):
      return "media/\(id)"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    return nil
  }

  public var jsonValue: Encodable? {
    switch self {
    case let .media(_, json):
      return json
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
