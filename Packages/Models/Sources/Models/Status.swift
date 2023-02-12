import Foundation

public struct Application: Codable, Identifiable, Hashable, Equatable {
  public var id: String {
    name
  }

  public let name: String
  public let website: URL?
}

public extension Application {
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    name = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
    website = try? values.decodeIfPresent(URL.self, forKey: .website)
  }
}

public enum Visibility: String, Codable, CaseIterable, Hashable, Equatable {
  case pub = "public"
  case unlisted
  case priv = "private"
  case direct
}

public protocol AnyStatus {
  var viewId: String { get }
  var id: String { get }
  var content: HTMLString { get }
  var account: Account { get }
  var createdAt: ServerDate { get }
  var editedAt: ServerDate? { get }
  var mediaAttachments: [MediaAttachment] { get }
  var mentions: [Mention] { get }
  var repliesCount: Int { get }
  var reblogsCount: Int { get }
  var favouritesCount: Int { get }
  var card: Card? { get }
  var favourited: Bool? { get }
  var reblogged: Bool? { get }
  var pinned: Bool? { get }
  var bookmarked: Bool? { get }
  var emojis: [Emoji] { get }
  var url: String? { get }
  var application: Application? { get }
  var inReplyToAccountId: String? { get }
  var visibility: Visibility { get }
  var poll: Poll? { get }
  var spoilerText: HTMLString { get }
  var filtered: [Filtered]? { get }
  var sensitive: Bool { get }
  var language: String? { get }
}

public extension AnyStatus {
  var viewId: String {
    if let editedAt {
      return "\(id)\(editedAt.asDate.description)"
    }
    return id
  }
}

protocol StatusUI {
  var userMentioned: Bool? { get set }
}

public struct Status: AnyStatus, Codable, Identifiable, Equatable, Hashable, StatusUI {
  public var userMentioned: Bool?

  public static func == (lhs: Status, rhs: Status) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public let id: String
  public let content: HTMLString
  public let account: Account
  public let createdAt: ServerDate
  public let editedAt: ServerDate?
  public let reblog: ReblogStatus?
  public let mediaAttachments: [MediaAttachment]
  public let mentions: [Mention]
  public let repliesCount: Int
  public let reblogsCount: Int
  public let favouritesCount: Int
  public let card: Card?
  public let favourited: Bool?
  public let reblogged: Bool?
  public let pinned: Bool?
  public let bookmarked: Bool?
  public let emojis: [Emoji]
  public let url: String?
  public let application: Application?
  public let inReplyToAccountId: String?
  public let visibility: Visibility
  public let poll: Poll?
  public let spoilerText: HTMLString
  public let filtered: [Filtered]?
  public let sensitive: Bool
  public let language: String?

  public static func placeholder(forSettings: Bool = false, language: String? = nil) -> Status {
    .init(id: UUID().uuidString,
          content: .init(stringValue: "Lorem ipsum [#dolor](#) sit amet\nconsectetur [@adipiscing](#) elit\nAsed do eiusmod tempor incididunt ut labore.", parseMarkdown: forSettings),

          account: .placeholder(),
          createdAt: ServerDate(),
          editedAt: nil,
          reblog: nil,
          mediaAttachments: [],
          mentions: [],
          repliesCount: 0,
          reblogsCount: 0,
          favouritesCount: 0,
          card: nil,
          favourited: false,
          reblogged: false,
          pinned: false,
          bookmarked: false,
          emojis: [],
          url: "https://example.com",
          application: nil,
          inReplyToAccountId: nil,
          visibility: .pub,
          poll: nil,
          spoilerText: .init(stringValue: ""),
          filtered: [],
          sensitive: false,
          language: language)
  }

  public static func placeholders() -> [Status] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }

  public var reblogAsAsStatus: Status? {
    if let reblog {
      return .init(id: reblog.id,
                   content: reblog.content,
                   account: reblog.account,
                   createdAt: reblog.createdAt,
                   editedAt: reblog.editedAt,
                   reblog: nil,
                   mediaAttachments: reblog.mediaAttachments,
                   mentions: reblog.mentions,
                   repliesCount: reblog.repliesCount,
                   reblogsCount: reblog.reblogsCount,
                   favouritesCount: reblog.favouritesCount,
                   card: reblog.card,
                   favourited: reblog.favourited,
                   reblogged: reblog.reblogged,
                   pinned: reblog.pinned,
                   bookmarked: reblog.bookmarked,
                   emojis: reblog.emojis,
                   url: reblog.url,
                   application: reblog.application,
                   inReplyToAccountId: reblog.inReplyToAccountId,
                   visibility: reblog.visibility,
                   poll: reblog.poll,
                   spoilerText: reblog.spoilerText,
                   filtered: reblog.filtered,
                   sensitive: reblog.sensitive,
                   language: reblog.language)
    }
    return nil
  }
}

public struct ReblogStatus: AnyStatus, Codable, Identifiable, Equatable, Hashable {
  public static func == (lhs: ReblogStatus, rhs: ReblogStatus) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public let id: String
  public let content: HTMLString
  public let account: Account
  public let createdAt: ServerDate
  public let editedAt: ServerDate?
  public let mediaAttachments: [MediaAttachment]
  public let mentions: [Mention]
  public let repliesCount: Int
  public let reblogsCount: Int
  public let favouritesCount: Int
  public let card: Card?
  public let favourited: Bool?
  public let reblogged: Bool?
  public let pinned: Bool?
  public let bookmarked: Bool?
  public let emojis: [Emoji]
  public let url: String?
  public var application: Application?
  public let inReplyToAccountId: String?
  public let visibility: Visibility
  public let poll: Poll?
  public let spoilerText: HTMLString
  public let filtered: [Filtered]?
  public let sensitive: Bool
  public let language: String?
}
