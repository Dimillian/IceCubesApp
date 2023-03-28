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

  public var jsonValue: Encodable? {
    switch self {
    case let .token(code, clientId, clientSecret):
      return TokenData(clientId: clientId, clientSecret: clientSecret, code: code)
    default:
      return nil
    }
  }

  public struct TokenData: Encodable {
    public let grantType = "authorization_code"
    public let clientId: String
    public let clientSecret: String
    public let redirectUri = AppInfo.scheme
    public let code: String
    public let scope = AppInfo.scopes
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
    default:
      return nil
    }
  }
}
