import Foundation

/// A Mastodon Collection (4.6+): a public or unlisted, shareable curated list of accounts,
/// shown on the curator's profile. Named `AccountCollection` to avoid clashing with
/// `Swift.Collection`.
public struct AccountCollection: Codable, Identifiable, Equatable, Hashable {
  public struct ShallowTag: Codable, Equatable, Hashable, Sendable {
    public let name: String
    public let url: String
  }

  public struct Item: Codable, Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let accountId: String?
    /// `pending`, `accepted`, `rejected`, or `revoked`.
    public let state: String
    public let createdAt: ServerDate
  }

  public let id: String
  public let accountId: String
  public let uri: String
  public let url: URL?
  public let name: String
  public let description: HTMLString
  public let language: String?
  public let local: Bool
  public let sensitive: Bool
  public let discoverable: Bool
  public let tag: ShallowTag?
  public let createdAt: ServerDate
  public let updatedAt: ServerDate
  public let itemCount: Int
  public let items: [Item]

  public var acceptedAccountIds: [String] {
    items.compactMap { item in
      item.state == "accepted" ? item.accountId : nil
    }
  }
}

extension AccountCollection: Sendable {}

/// Response shape of `GET /api/v1/accounts/:id/collections`.
public struct AccountCollectionsResponse: Codable, Sendable {
  public let collections: [AccountCollection]
}

/// Response shape of `GET /api/v1/collections/:id`, which also includes the
/// member accounts.
public struct AccountCollectionResponse: Codable, Sendable {
  public let collection: AccountCollection
  public let accounts: [Account]
}
