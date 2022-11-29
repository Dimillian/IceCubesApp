import Foundation

public struct Account: Codable, Identifiable {
  public let id: String
  public let username: String
  public let displayName: String
  public let avatar: URL
  public let acct: String
}
