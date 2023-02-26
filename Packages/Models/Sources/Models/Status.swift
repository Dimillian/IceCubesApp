import Foundation
import Atomics

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

public enum Visibility: String, Codable, CaseIterable, Hashable, Equatable, Sendable {
  case pub = "public"
  case unlisted
  case priv = "private"
  case direct
}

public protocol AnyStatus {
  var viewId: StatusViewId { get }
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
  var inReplyToId: String? { get }
  var inReplyToAccountId: String? { get }
  var visibility: Visibility { get }
  var poll: Poll? { get }
  var spoilerText: HTMLString { get }
  var filtered: [Filtered]? { get }
  var sensitive: Bool { get }
  var language: String? { get }
}

public struct StatusViewId: Hashable {
  let id: String
  let editedAt: Date?
}

public extension AnyStatus {
  var viewId: StatusViewId {
    StatusViewId(id: id, editedAt: editedAt?.asDate)
  }
}

protocol StatusUI {
  var userMentioned: Bool? { get set }
}

public final class Status: AnyStatus, Codable, Identifiable, Equatable, Hashable, StatusUI {
  private let _userMentioned: UnsafeAtomic<Bool>
  public var userMentioned: Bool? {
    get { _userMentioned.load(ordering: .relaxed) }
    set { _userMentioned.store(newValue ?? false, ordering: .relaxed) }
  }

  public static func == (lhs: Status, rhs: Status) -> Bool {
    lhs.id == rhs.id && lhs.viewId == rhs.viewId
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
  public let inReplyToId: String?
  public let inReplyToAccountId: String?
  public let visibility: Visibility
  public let poll: Poll?
  public let spoilerText: HTMLString
  public let filtered: [Filtered]?
  public let sensitive: Bool
  public let language: String?

  public init(userMentioned: Bool? = nil, id: String, content: HTMLString, account: Account, createdAt: ServerDate, editedAt: ServerDate?, reblog: ReblogStatus?, mediaAttachments: [MediaAttachment], mentions: [Mention], repliesCount: Int, reblogsCount: Int, favouritesCount: Int, card: Card?, favourited: Bool?, reblogged: Bool?, pinned: Bool?, bookmarked: Bool?, emojis: [Emoji], url: String?, application: Application?, inReplyToId: String?, inReplyToAccountId: String?, visibility: Visibility, poll: Poll?, spoilerText: HTMLString, filtered: [Filtered]?, sensitive: Bool, language: String?) {
    self._userMentioned = .create(userMentioned ?? false)
    self.id = id
    self.content = content
    self.account = account
    self.createdAt = createdAt
    self.editedAt = editedAt
    self.reblog = reblog
    self.mediaAttachments = mediaAttachments
    self.mentions = mentions
    self.repliesCount = repliesCount
    self.reblogsCount = reblogsCount
    self.favouritesCount = favouritesCount
    self.card = card
    self.favourited = favourited
    self.reblogged = reblogged
    self.pinned = pinned
    self.bookmarked = bookmarked
    self.emojis = emojis
    self.url = url
    self.application = application
    self.inReplyToId = inReplyToId
    self.inReplyToAccountId = inReplyToAccountId
    self.visibility = visibility
    self.poll = poll
    self.spoilerText = spoilerText
    self.filtered = filtered
    self.sensitive = sensitive
    self.language = language
  }

  deinit {
    // Clean up the atomic variable storage
    _userMentioned.destroy()
  }

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
          inReplyToId: nil,
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
                   inReplyToId: reblog.inReplyToId,
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

  // MARK: Codable Conformance

  // Alas, UnsafeAtomic is not Codable, so we need to implement it all ourselves.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let userMentioned = try container.decodeIfPresent(Bool.self, forKey: .userMentioned)
    self._userMentioned = .create(userMentioned ?? false)
    self.id = try container.decode(String.self, forKey: .id)
    self.content = try container.decode(HTMLString.self, forKey: .content)
    self.account = try container.decode(Account.self, forKey: .account)
    self.createdAt = try container.decode(ServerDate.self, forKey: .createdAt)
    self.editedAt = try container.decodeIfPresent(ServerDate.self, forKey: .editedAt)
    self.reblog = try container.decodeIfPresent(ReblogStatus.self, forKey: .reblog)
    self.mediaAttachments = try container.decode([MediaAttachment].self, forKey: .mediaAttachments)
    self.mentions = try container.decode([Mention].self, forKey: .mentions)
    self.repliesCount = try container.decode(Int.self, forKey: .repliesCount)
    self.reblogsCount = try container.decode(Int.self, forKey: .reblogsCount)
    self.favouritesCount = try container.decode(Int.self, forKey: .favouritesCount)
    self.card = try container.decodeIfPresent(Card.self, forKey: .card)
    self.favourited = try container.decodeIfPresent(Bool.self, forKey: .favourited)
    self.reblogged = try container.decodeIfPresent(Bool.self, forKey: .reblogged)
    self.pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned)
    self.bookmarked = try container.decodeIfPresent(Bool.self, forKey: .bookmarked)
    self.emojis = try container.decode([Emoji].self, forKey: .emojis)
    self.url = try container.decodeIfPresent(String.self, forKey: .url)
    self.application = try container.decodeIfPresent(Application.self, forKey: .application)
    self.inReplyToId = try container.decodeIfPresent(String.self, forKey: .inReplyToId)
    self.inReplyToAccountId = try container.decodeIfPresent(String.self, forKey: .inReplyToAccountId)
    self.visibility = try container.decode(Visibility.self, forKey: .visibility)
    self.poll = try container.decodeIfPresent(Poll.self, forKey: .poll)
    self.spoilerText = try container.decode(HTMLString.self, forKey: .spoilerText)
    self.filtered = try container.decodeIfPresent([Filtered].self, forKey: .filtered)
    self.sensitive = try container.decode(Bool.self, forKey: .sensitive)
    self.language = try container.decodeIfPresent(String.self, forKey: .language)
  }

  private enum CodingKeys: CodingKey {
    case userMentioned, id, content, account, createdAt, editedAt, reblog
    case mediaAttachments, mentions, repliesCount, reblogsCount, favouritesCount
    case card, favourited, reblogged, pinned, bookmarked, emojis, url
    case application, inReplyToId, inReplyToAccountId, visibility, poll
    case spoilerText, filtered, sensitive, language
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(self.userMentioned, forKey: .userMentioned)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.content, forKey: .content)
    try container.encode(self.account, forKey: .account)
    try container.encode(self.createdAt, forKey: .createdAt)
    try container.encodeIfPresent(self.editedAt, forKey: .editedAt)
    try container.encodeIfPresent(self.reblog, forKey: .reblog)
    try container.encode(self.mediaAttachments, forKey: .mediaAttachments)
    try container.encode(self.mentions, forKey: .mentions)
    try container.encode(self.repliesCount, forKey: .repliesCount)
    try container.encode(self.reblogsCount, forKey: .reblogsCount)
    try container.encode(self.favouritesCount, forKey: .favouritesCount)
    try container.encodeIfPresent(self.card, forKey: .card)
    try container.encodeIfPresent(self.favourited, forKey: .favourited)
    try container.encodeIfPresent(self.reblogged, forKey: .reblogged)
    try container.encodeIfPresent(self.pinned, forKey: .pinned)
    try container.encodeIfPresent(self.bookmarked, forKey: .bookmarked)
    try container.encode(self.emojis, forKey: .emojis)
    try container.encodeIfPresent(self.url, forKey: .url)
    try container.encodeIfPresent(self.application, forKey: .application)
    try container.encodeIfPresent(self.inReplyToId, forKey: .inReplyToId)
    try container.encodeIfPresent(self.inReplyToAccountId, forKey: .inReplyToAccountId)
    try container.encode(self.visibility, forKey: .visibility)
    try container.encodeIfPresent(self.poll, forKey: .poll)
    try container.encode(self.spoilerText, forKey: .spoilerText)
    try container.encodeIfPresent(self.filtered, forKey: .filtered)
    try container.encode(self.sensitive, forKey: .sensitive)
    try container.encodeIfPresent(self.language, forKey: .language)
  }
}

public final class ReblogStatus: AnyStatus, Codable, Identifiable, Equatable, Hashable {
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
  public let application: Application?
  public let inReplyToId: String?
  public let inReplyToAccountId: String?
  public let visibility: Visibility
  public let poll: Poll?
  public let spoilerText: HTMLString
  public let filtered: [Filtered]?
  public let sensitive: Bool
  public let language: String?

  public init(id: String, content: HTMLString, account: Account, createdAt: ServerDate, editedAt: ServerDate?, mediaAttachments: [MediaAttachment], mentions: [Mention], repliesCount: Int, reblogsCount: Int, favouritesCount: Int, card: Card?, favourited: Bool?, reblogged: Bool?, pinned: Bool?, bookmarked: Bool?, emojis: [Emoji], url: String?, application: Application? = nil, inReplyToId: String?, inReplyToAccountId: String?, visibility: Visibility, poll: Poll?, spoilerText: HTMLString, filtered: [Filtered]?, sensitive: Bool, language: String?) {
    self.id = id
    self.content = content
    self.account = account
    self.createdAt = createdAt
    self.editedAt = editedAt
    self.mediaAttachments = mediaAttachments
    self.mentions = mentions
    self.repliesCount = repliesCount
    self.reblogsCount = reblogsCount
    self.favouritesCount = favouritesCount
    self.card = card
    self.favourited = favourited
    self.reblogged = reblogged
    self.pinned = pinned
    self.bookmarked = bookmarked
    self.emojis = emojis
    self.url = url
    self.application = application
    self.inReplyToId = inReplyToId
    self.inReplyToAccountId = inReplyToAccountId
    self.visibility = visibility
    self.poll = poll
    self.spoilerText = spoilerText
    self.filtered = filtered
    self.sensitive = sensitive
    self.language = language
  }
}

extension Application: Sendable {}
extension StatusViewId: Sendable {}

// Every property in Status is immutable, with the exception of
// `userMentioned`, which we have wrapped with UnsafeAtomic.
extension Status: Sendable {}

// Every property in ReblogStatus is immutable.
extension ReblogStatus: Sendable {}


