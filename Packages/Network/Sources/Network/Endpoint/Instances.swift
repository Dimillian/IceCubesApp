import Foundation

public enum Instances: Endpoint {
  case instance
  
  public func path() -> String {
    switch self {
    case .instance:
      return "instance"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
