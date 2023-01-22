import Foundation

public struct Application: Codable, Identifiable {
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

public struct Status: AnyStatus, Decodable, Identifiable {
  public var viewId: String {
    id + createdAt + (editedAt ?? "")
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

  public static func placeholder() -> Status {
    .init(id: UUID().uuidString,
          content: .init(stringValue: "This is a #toot\nWith some @content\nAnd some more content for your #eyes @only"),
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
          spoilerText: .init(stringValue: ""),
          filtered: [],
          sensitive: false,
          language: nil)
  }

  public static func placeholders() -> [Status] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }

  public func didInteract() -> Bool {
    var postInfo: AnyStatus = self
    if let rebloggedStatus = reblog {
      postInfo = rebloggedStatus
    }
    return (postInfo.reblogged ?? false) || (postInfo.favourited ?? false) || (postInfo.bookmarked ?? false)
  }

  public func isRelevant() -> Bool {
    var postInfo: AnyStatus = self
    if let rebloggedStatus = reblog {
      postInfo = rebloggedStatus
    }
    return postInfo.repliesCount > 0 || postInfo.reblogsCount > 0 || postInfo.favouritesCount > 0
  }

  public var popularity: Double {
    var postInfo: AnyStatus = self
    if let rebloggedStatus = reblog {
      postInfo = rebloggedStatus
    }
    let criterias = [
      Double(postInfo.reblogsCount + 1),
      Double(postInfo.favouritesCount + 1),
      Double(postInfo.repliesCount + 1)
    ]
    var weight = Double(0)
    if postInfo.account.followersCount > 0 {
      weight = 1 / sqrt(Double(postInfo.account.followersCount))
    }
    return pow(criterias.reduce(Double(1), {x, y in x * y}), 1/Double(criterias.count)) * weight
  }
}

public struct ReblogStatus: AnyStatus, Decodable, Identifiable {
  public var viewId: String {
    id + createdAt + (editedAt ?? "")
  }

  public let id: String
  public let content: HTMLString
  public let account: Account
  public let createdAt: String
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
