import Foundation
import Models

public enum Oauth: Endpoint {
  case authorize(clientId: String)
  case token(code: String, clientId: String, clientSecret: String)

  public func path() -> String {
    switch self {
    case .authorize:
      return "oauth/authorize"
    case .token:
      return "oauth/token"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .authorize(clientId):
      return [
        .init(name: "response_type", value: "code"),
        .init(name: "client_id", value: clientId),
        .init(name: "redirect_uri", value: AppInfo.scheme),
        .init(name: "scope", value: AppInfo.scopes),
      ]
    case let .token(code, clientId, clientSecret):
      return [
        .init(name: "grant_type", value: "authorization_code"),
        .init(name: "client_id", value: clientId),
        .init(name: "client_secret", value: clientSecret),
        .init(name: "redirect_uri", value: AppInfo.scheme),
        .init(name: "code", value: code),
        .init(name: "scope", value: AppInfo.scopes),
      ]
    }
  }
}
