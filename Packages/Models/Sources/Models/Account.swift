import Foundation

public final class Account: Codable, Identifiable, Hashable, Sendable, Equatable {
  public static func == (lhs: Account, rhs: Account) -> Bool {
    lhs.id == rhs.id && lhs.username == rhs.username && lhs.note.asRawText == rhs.note.asRawText
      && lhs.statusesCount == rhs.statusesCount && lhs.followersCount == rhs.followersCount
      && lhs.followingCount == rhs.followingCount && lhs.acct == rhs.acct
      && lhs.displayName == rhs.displayName && lhs.fields == rhs.fields
      && lhs.lastStatusAt == rhs.lastStatusAt && lhs.discoverable == rhs.discoverable
      && lhs.bot == rhs.bot && lhs.locked == rhs.locked && lhs.avatar == rhs.avatar
      && lhs.header == rhs.header
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
    public let privacy: Visibility?
    public let sensitive: Bool
    public let language: String?
    public let note: String
    public let fields: [Field]
  }

  public let id: String
  public let username: String
  public let displayName: String?
  public let cachedDisplayName: HTMLString
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
  public let moved: Account?

  public var haveAvatar: Bool {
    avatar.lastPathComponent != "missing.png"
  }

  public var haveHeader: Bool {
    header.lastPathComponent != "missing.png"
  }

  public var fullAccountName: String {
    "\(acct)@\(url?.host() ?? "")"
  }

  public init(
    id: String, username: String, displayName: String?, avatar: URL, header: URL, acct: String,
    note: HTMLString, createdAt: ServerDate, followersCount: Int, followingCount: Int,
    statusesCount: Int, lastStatusAt: String? = nil, fields: [Account.Field], locked: Bool,
    emojis: [Emoji], url: URL? = nil, source: Account.Source? = nil, bot: Bool,
    discoverable: Bool? = nil, moved: Account? = nil
  ) {
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
    self.moved = moved

    if let displayName, !displayName.isEmpty {
      cachedDisplayName = .init(stringValue: displayName)
    } else {
      cachedDisplayName = .init(stringValue: "@\(username)")
    }
  }

  public enum CodingKeys: CodingKey {
    case id
    case username
    case displayName
    case avatar
    case header
    case acct
    case note
    case createdAt
    case followersCount
    case followingCount
    case statusesCount
    case lastStatusAt
    case fields
    case locked
    case emojis
    case url
    case source
    case bot
    case discoverable
    case moved
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    username = try container.decode(String.self, forKey: .username)
    displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
    avatar = try container.decode(URL.self, forKey: .avatar)
    header = try container.decode(URL.self, forKey: .header)
    acct = try container.decode(String.self, forKey: .acct)
    note = try container.decode(HTMLString.self, forKey: .note)
    createdAt = try container.decode(ServerDate.self, forKey: .createdAt)
    followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount)
    followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount)
    statusesCount = try container.decodeIfPresent(Int.self, forKey: .statusesCount)
    lastStatusAt = try container.decodeIfPresent(String.self, forKey: .lastStatusAt)
    fields = try container.decode([Account.Field].self, forKey: .fields)
    locked = try container.decode(Bool.self, forKey: .locked)
    emojis = try container.decode([Emoji].self, forKey: .emojis)
    url = try container.decodeIfPresent(URL.self, forKey: .url)
    source = try container.decodeIfPresent(Account.Source.self, forKey: .source)
    bot = try container.decode(Bool.self, forKey: .bot)
    discoverable = try container.decodeIfPresent(Bool.self, forKey: .discoverable)
    moved = try container.decodeIfPresent(Account.self, forKey: .moved)

    if let displayName, !displayName.isEmpty {
      cachedDisplayName = .init(stringValue: displayName)
    } else {
      cachedDisplayName = .init(stringValue: "@\(username)")
    }
  }

  public static func placeholder() -> Account {
    .init(
      id: UUID().uuidString,
      username: "Username",
      displayName: "John Mastodon",
      avatar: URL(
        string:
          "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png"
      )!,
      header: URL(
        string:
          "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png"
      )!,
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
    [
      .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
      .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
    ]
  }
}

public struct FamiliarAccounts: Decodable {
  public let id: String
  public let accounts: [Account]
}

extension FamiliarAccounts: Sendable {}
