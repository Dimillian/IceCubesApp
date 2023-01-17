import Foundation

public enum Streaming: Endpoint {
  case streaming

  public func path() -> String {
    switch self {
    case .streaming:
      return "streaming"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    default:
      return nil
    }
  }
}
