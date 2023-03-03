import Foundation

public struct Mention: Codable, Equatable, Hashable {
  public let id: String
  public let username: String
  public let url: URL
  public let acct: String
}

extension Mention: Sendable {}
