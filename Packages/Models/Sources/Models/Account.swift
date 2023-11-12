import Foundation

public final class Account: Codable, Identifiable, Hashable, Sendable, Equatable {
  public static func == (lhs: Account, rhs: Account) -> Bool {
    lhs.id == rhs.id &&
      lhs.username == rhs.username &&
      lhs.note.asRawText == rhs.note.asRawText &&
      lhs.statusesCount == rhs.statusesCount &&
      lhs.followersCount == rhs.followersCount &&
      lhs.followingCount == rhs.followingCount &&
      lhs.acct == rhs.acct &&
      lhs.displayName == rhs.displayName &&
      lhs.fields == rhs.fields &&
      lhs.lastStatusAt == rhs.lastStatusAt &&
      lhs.discoverable == rhs.discoverable &&
      lhs.bot == rhs.bot &&
      lhs.locked == rhs.locked
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public struct Field: Codable, Equatable, Identifiable, Sendable {
    public var id: String {
      value.asRawText + name
    }

    public let name: String
    public let value: HTMLString
    public let verifiedAt: String?
  }

  public struct Source: Codable, Equatable, Sendable {
    public let privacy: Visibility
    public let sensitive: Bool
    public let language: String?
    public let note: String
    public let fields: [Field]
  }

  public let id: String
  public let username: String
  public let displayName: String?
  public let avatar: URL
  public let header: URL
  public let acct: String
  public let note: HTMLString
  public let createdAt: ServerDate
  public let followersCount: Int?
  public let followingCount: Int?
  public let statusesCount: Int?
  public let lastStatusAt: String?
  public let fields: [Field]
  public let locked: Bool
  public let emojis: [Emoji]
  public let url: URL?
  public let source: Source?
  public let bot: Bool
  public let discoverable: Bool?

  public var haveAvatar: Bool {
    avatar.lastPathComponent != "missing.png"
  }

  public var haveHeader: Bool {
    header.lastPathComponent != "missing.png"
  }

  public init(id: String, username: String, displayName: String?, avatar: URL, header: URL, acct: String, note: HTMLString, createdAt: ServerDate, followersCount: Int, followingCount: Int, statusesCount: Int, lastStatusAt: String? = nil, fields: [Account.Field], locked: Bool, emojis: [Emoji], url: URL? = nil, source: Account.Source? = nil, bot: Bool, discoverable: Bool? = nil) {
    self.id = id
    self.username = username
    self.displayName = displayName
    self.avatar = avatar
    self.header = header
    self.acct = acct
    self.note = note
    self.createdAt = createdAt
    self.followersCount = followersCount
    self.followingCount = followingCount
    self.statusesCount = statusesCount
    self.lastStatusAt = lastStatusAt
    self.fields = fields
    self.locked = locked
    self.emojis = emojis
    self.url = url
    self.source = source
    self.bot = bot
    self.discoverable = discoverable
  }

  public static func placeholder() -> Account {
    .init(id: UUID().uuidString,
          username: "Username",
          displayName: "John Mastodon",
          avatar: URL(string: "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png")!,
          header: URL(string: "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png")!,
          acct: "johnm@example.com",
          note: .init(stringValue: "Some content"),
          createdAt: ServerDate(),
          followersCount: 10,
          followingCount: 10,
          statusesCount: 10,
          lastStatusAt: nil,
          fields: [],
          locked: false,
          emojis: [],
          url: nil,
          source: nil,
          bot: false,
          discoverable: true)
  }

  public static func placeholders() -> [Account] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
     .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}

public struct FamiliarAccounts: Decodable {
  public let id: String
  public let accounts: [Account]
}

extension FamiliarAccounts: Sendable {}
