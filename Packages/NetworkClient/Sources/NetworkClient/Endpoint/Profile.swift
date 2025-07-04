import Foundation

public enum Profile: Endpoint {
  case deleteAvatar
  case deleteHeader

  public func path() -> String {
    switch self {
    case .deleteAvatar:
      "profile/avatar"
    case .deleteHeader:
      "profile/header"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .deleteAvatar, .deleteHeader:
      nil
    }
  }
}
