import Foundation

public enum Visibility: String, Codable, CaseIterable, Hashable, Equatable, Sendable {
  case pub = "public"
  case unlisted
  case priv = "private"
  case direct
}

public protocol AnyStatus {
  var id: String { get }
  var content: HTMLString { get }
  var account: Account { get }
  var createdAt: ServerDate { get }
  var editedAt: ServerDate? { get }
  var mediaAttachments: [MediaAttachment] { get }
  var mentions: [Mention] { get }
  var repliesCount: Int { get }
  var reblogsCount: Int { get }
  var quotesCount: Int? { get }
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
  var tags: [Tag] { get }
  var isHidden: Bool { get }
  var quote: Quote? { get }
  var quoteApproval: QuoteApproval? { get }
}

public final class Status: AnyStatus, Codable, Identifiable, Equatable, Hashable {
  public static func == (lhs: Status, rhs: Status) -> Bool {
    lhs.id == rhs.id && lhs.editedAt?.asDate == rhs.editedAt?.asDate
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
  public let quotesCount: Int?
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
  public let tags: [Tag]
  public let quote: Quote?
  public let quoteApproval: QuoteApproval?

  public var isHidden: Bool {
    filtered?.first?.filter.filterAction == .hide
  }

  public var asMediaStatus: [MediaStatus] {
    mediaAttachments.map { .init(status: self, attachment: $0) }
  }

  public init(
    id: String, content: HTMLString, account: Account, createdAt: ServerDate, editedAt: ServerDate?,
    reblog: ReblogStatus?, mediaAttachments: [MediaAttachment], mentions: [Mention],
    repliesCount: Int, reblogsCount: Int, favouritesCount: Int, card: Card?, favourited: Bool?,
    reblogged: Bool?, pinned: Bool?, bookmarked: Bool?, emojis: [Emoji], url: String?,
    application: Application?, inReplyToId: String?, inReplyToAccountId: String?,
    visibility: Visibility, poll: Poll?, spoilerText: HTMLString, filtered: [Filtered]?,
    sensitive: Bool, language: String?, tags: [Tag] = [], quote: Quote?, quotesCount: Int?,
    quoteApproval: QuoteApproval?
  ) {
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
    self.tags = tags
    self.quote = quote
    self.quotesCount = quotesCount
    self.quoteApproval = quoteApproval
  }

  public static func placeholder(forSettings: Bool = false, language: String? = nil) -> Status {
    .init(
      id: UUID().uuidString,
      content: .init(
        stringValue:
          "Here's to the [#crazy](#) ones. The misfits.\nThe [@rebels](#). The troublemakers.",
        parseMarkdown: forSettings),

      account: .placeholder(),
      createdAt: ServerDate(),
      editedAt: nil,
      reblog: nil,
      mediaAttachments: [],
      mentions: [],
      repliesCount: 34,
      reblogsCount: 8,
      favouritesCount: 150,
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
      language: language,
      tags: [],
      quote: nil,
      quotesCount: 2,
      quoteApproval: nil)
  }

  public static func placeholders() -> [Status] {
    [
      .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
      .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
    ]
  }

  public var reblogAsAsStatus: Status? {
    if let reblog {
      return .init(
        id: reblog.id,
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
        language: reblog.language,
        tags: reblog.tags,
        quote: reblog.quote,
        quotesCount: reblog.quotesCount,
        quoteApproval: reblog.quoteApproval)
    }
    return nil
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
  public let quotesCount: Int?
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
  public let tags: [Tag]
  public let quote: Quote?
  public let quoteApproval: QuoteApproval?

  public var isHidden: Bool {
    filtered?.first?.filter.filterAction == .hide
  }

  public init(
    id: String, content: HTMLString, account: Account, createdAt: ServerDate, editedAt: ServerDate?,
    mediaAttachments: [MediaAttachment], mentions: [Mention], repliesCount: Int, reblogsCount: Int,
    favouritesCount: Int, card: Card?, favourited: Bool?, reblogged: Bool?, pinned: Bool?,
    bookmarked: Bool?, emojis: [Emoji], url: String?, application: Application? = nil,
    inReplyToId: String?, inReplyToAccountId: String?, visibility: Visibility, poll: Poll?,
    spoilerText: HTMLString, filtered: [Filtered]?, sensitive: Bool, language: String?,
    tags: [Tag] = [], quote: Quote?, quotesCount: Int?, quoteApproval: QuoteApproval?
  ) {
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
    self.tags = tags
    self.quote = quote
    self.quotesCount = quotesCount
    self.quoteApproval = quoteApproval
  }
}

// Every property in Status is immutable.
extension Status: Sendable {}

// Every property in ReblogStatus is immutable.
extension ReblogStatus: Sendable {}
