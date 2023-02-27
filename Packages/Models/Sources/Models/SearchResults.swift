import Foundation

public struct SearchResults: Decodable {
  enum CodingKeys: String, CodingKey {
    case accounts, statuses, hashtags
  }

  public let accounts: [Account]
  public var relationships: [Relationship] = []
  public let statuses: [Status]
  public let hashtags: [Tag]

  public var isEmpty: Bool {
    accounts.isEmpty && statuses.isEmpty && hashtags.isEmpty
  }
}

extension SearchResults: Sendable {}
