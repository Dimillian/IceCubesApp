import Foundation

public struct OauthToken: Codable {
  public let accessToken: String
  public let tokenType: String
  public let scope: String
  public let createdAt: Double
}
