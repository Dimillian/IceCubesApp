import Foundation

public struct Status: Codable, Identifiable {
  public let id: String
  public let content: String
  public let account: Account
}
