import Foundation

public struct SearchResults: Decodable {
  enum CodingKeys: String, CodingKey {
    case accounts, statuses, hashtags
  }

  public var accounts: [Account]
  public var relationships: [Relationship] = []
  public var statuses: [Status]
  public var hashtags: [Tag]

  public var isEmpty: Bool {
    accounts.isEmpty && statuses.isEmpty && hashtags.isEmpty
  }
}

extension SearchResults: Sendable {}
