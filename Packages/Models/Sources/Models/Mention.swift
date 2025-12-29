import Foundation

public struct Mention: Codable, Equatable, Hashable {
  public let id: String
  public let username: String
  public let url: URL
  public let acct: String

  public init(id: String, username: String, url: URL, acct: String) {
    self.id = id
    self.username = username
    self.url = url
    self.acct = acct
  }
}

extension Mention: Sendable {}
