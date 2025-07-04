import Foundation

public enum CustomEmojis: Endpoint {
  case customEmojis

  public func path() -> String {
    switch self {
    case .customEmojis:
      "custom_emojis"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
