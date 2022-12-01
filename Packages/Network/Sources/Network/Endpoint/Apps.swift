import Foundation

public enum Apps: Endpoint {
  case registerApp
  
  public func path() -> String {
    switch self {
    case .registerApp:
      return "apps"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .registerApp:
      return [
        .init(name: "client_name", value: "IceCubesApp"),
        .init(name: "redirect_uris", value: "icecubesapp://"),
        .init(name: "scopes", value: "read write follow push"),
        .init(name: "website", value: "https://github.com/Dimillian/IceCubesApp")
      ]
    }
  }
}
