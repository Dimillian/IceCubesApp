import Foundation

public struct Application: Codable, Identifiable {
  public var id: String {
    name
  }
  public let name: String
  public let website: URL?
}

extension Application {
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    name = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
    website = try? values.decodeIfPresent(URL.self, forKey: .website)
  }
}

public enum Visibility: String, Codable, CaseIterable {
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
  var mediaAttachments: [MediaAttachement] { get }
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
  var url: URL? { get }
  var application: Application? { get }
  var inReplyToAccountId: String? { get }
  var visibility: Visibility { get }
  var poll: Poll? { get }
  var spoilerText: String { get }
  var filtered: [Filtered]? { get }
  var sensitive: Bool { get }
}


public struct Status: AnyStatus, Codable, Identifiable {
  public var viewId: String {
    id + createdAt + (editedAt ?? "")
  }
  
  public let id: String
  public let content: HTMLString
  public let account: Account
  public let createdAt: ServerDate
  public let editedAt: ServerDate?
  public let reblog: ReblogStatus?
  public let mediaAttachments: [MediaAttachement]
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
  public let url: URL?
  public let application: Application?
  public let inReplyToAccountId: String?
  public let visibility: Visibility
  public let poll: Poll?
  public let spoilerText: String
  public let filtered: [Filtered]?
  public let sensitive: Bool
  
  public static func placeholder() -> Status {
    .init(id: UUID().uuidString,
          content: "This is a #toot\nWith some @content\nAnd some more content for your #eyes @only",
          account: .placeholder(),
          createdAt: "2022-12-16T10:20:54.000Z",
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
          url: nil,
          application: nil,
          inReplyToAccountId: nil,
          visibility: .pub,
          poll: nil,
          spoilerText: "",
          filtered: [],
          sensitive: false)
  }
  
  public static func placeholders() -> [Status] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}

public struct ReblogStatus: AnyStatus, Codable, Identifiable {
  public var viewId: String {
    id + createdAt + (editedAt ?? "")
  }
  
  public let id: String
  public let content: String
  public let account: Account
  public let createdAt: String
  public let editedAt: ServerDate?
  public let mediaAttachments: [MediaAttachement]
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
  public let url: URL?
  public var application: Application?
  public let inReplyToAccountId: String?
  public let visibility: Visibility
  public let poll: Poll?
  public let spoilerText: String
  public let filtered: [Filtered]?
  public let sensitive: Bool
}
