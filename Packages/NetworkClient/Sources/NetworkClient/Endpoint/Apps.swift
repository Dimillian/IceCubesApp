import Foundation
import Models

private struct InstanceAppRequest: Codable, Sendable {
  public let clientName: String
  public let redirectUris: String
  public let scopes: String
  public let website: String
}

public enum Apps: Endpoint {
  case registerApp

  public func path() -> String {
    switch self {
    case .registerApp:
      "apps"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    nil
  }

  public var jsonValue: Encodable? {
    switch self {
    case .registerApp:
      InstanceAppRequest(
        clientName: AppInfo.clientName, redirectUris: AppInfo.scheme, scopes: AppInfo.scopes,
        website: AppInfo.weblink)
    }
  }
}
