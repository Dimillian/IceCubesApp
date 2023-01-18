import Foundation

public enum CustomEmojis: Endpoint {
  case customEmojis

  public func path() -> String {
    switch self {
    case .customEmojis:
      return "custom_emojis"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
