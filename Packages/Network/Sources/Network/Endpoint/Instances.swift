import Foundation

public enum Instances: Endpoint {
  case instance
  case peers

  public func path() -> String {
    switch self {
    case .instance:
      return "instance"
    case .peers:
      return "instance/peers"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
