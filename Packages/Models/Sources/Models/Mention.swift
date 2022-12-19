import Foundation

public struct Mention: Codable {
  public let id: String
  public let username: String
  public let url: URL
  public let acct: String
}
