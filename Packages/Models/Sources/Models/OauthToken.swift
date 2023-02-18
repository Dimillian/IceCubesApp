import Foundation

public struct OauthToken: Codable, Hashable, Sendable {
  public let accessToken: String
  public let tokenType: String
  public let scope: String
  public let createdAt: Double
}
