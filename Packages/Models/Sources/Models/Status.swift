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
  var favourited: Bool { get }
  var reblogged: Bool { get }
  var pinned: Bool { get }
  var bookmarked: Bool { get }
  var emojis: [Emoji] { get }
  var url: String { get }
  var application: Application? { get }
  var inReplyToAccountId: String { get }
  var visibility: Visibility { get }
  var poll: Poll? { get }
  var spoilerText: HTMLString { get }
  var filtered: [Filtered] { get }
  var sensitive: Bool { get }
  var language: String { get }
}

public struct Status: AnyStatus, Decodable, Identifiable, Equatable, Hashable {
  public var viewId: String {
    id + createdAt + (editedAt ?? "")
  }
  
  public static func == (lhs: Status, rhs: Status) -> Bool {
    lhs.id == rhs.id
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public var id = ""
  public var content = HTMLString(stringValue: "")
  public var account: Account
  public var createdAt: ServerDate
  public var editedAt: ServerDate?
  public var reblog: ReblogStatus?
  public var mediaAttachments = [MediaAttachment]()
  public var mentions = [Mention]()
  public var repliesCount = 0
  public var reblogsCount = 0
  public var favouritesCount = 0
  public var card: Card?
  public var favourited = false
  public var reblogged = false
  public var pinned = false
  public var bookmarked = false
  public var emojis = [Emoji]()
  public var url = ""
  public var application: Application?
  public var inReplyToAccountId = ""
  public var visibility: Visibility
  public var poll: Poll?
  public var spoilerText = HTMLString(stringValue: "")
  public var filtered = [Filtered]()
  public var sensitive = false
  public var language = ""

  public static func placeholder() -> Status {
    return Status()
  }

  enum CodingKeys: String, CodingKey {
    case id, content, account, createdAt, editedAt, reblog, mediaAttachments, mentions, repliesCount, reblogsCount, favouritesCount
    case card, favourited, reblogged, pinned, bookmarked, emojis, url, application, inReplyToAccountId, visibility, poll, spoilerText
    case filtered, sensitive, language
  }
  
  public static func placeholders() -> [Status] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
  
  public init() {
    id = UUID().uuidString
    content = HTMLString(stringValue: "This is a #toot\nWith some @content\nAnd some more content for your #eyes @only")
    account = Account.placeholder()
    createdAt = "2022-12-16T10:20:54.000Z"
    visibility = Visibility.pub
    spoilerText = HTMLString(stringValue: "")
  }
  
  public init(from decoder: Decoder) throws {
    do {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      content = try values.decode(HTMLString.self, forKey: .content)
      account = try values.decode(Account.self, forKey: .account)
      createdAt = try values.decode(ServerDate.self, forKey: .createdAt)
      if let dt = try? values.decode(ServerDate.self, forKey: .editedAt) {
        editedAt = dt
      }
      if let r = try? values.decode(ReblogStatus.self, forKey: .reblog) {
        reblog = r
      }
      mediaAttachments = try values.decode([MediaAttachment].self, forKey: .mediaAttachments)
      mentions = try values.decode([Mention].self, forKey: .mentions)
      repliesCount = try values.decode(Int.self, forKey: .repliesCount)
      reblogsCount = try values.decode(Int.self, forKey: .reblogsCount)
      favouritesCount = try values.decode(Int.self, forKey: .favouritesCount)
      if let c = try? values.decode(Card.self, forKey: .card) {
        card = c
      }
      if let val = try? values.decode(Bool.self, forKey: .favourited) {
        favourited = val
      }
      if let val = try? values.decode(Bool.self, forKey: .reblogged) {
        reblogged = val
      }
      if let val = try? values.decode(Bool.self, forKey: .pinned) {
        pinned = val
      }
      if let val = try? values.decode(Bool.self, forKey: .bookmarked) {
        bookmarked = val
      }
      emojis = try values.decode([Emoji].self, forKey: .emojis)
      if let u = try? values.decode(String.self, forKey: .url) {
        url = u
      }
      if let app = try? values.decode(Application.self, forKey: .application) {
        application = app
      }
      if let txt = try? values.decode(String.self, forKey: .inReplyToAccountId) {
        inReplyToAccountId = txt
      }
      visibility = try values.decode(Visibility.self, forKey: .visibility)
      if let p = try? values.decode(Poll.self, forKey: .poll) {
        poll = p
      }
	  if let html = try? values.decode(HTMLString.self, forKey: .spoilerText) {
		spoilerText = html
	  }
      if let arr = try? values.decode([Filtered].self, forKey: .filtered) {
        filtered = arr
      }
      if let val = try? values.decode(Bool.self, forKey: .sensitive) {
        sensitive = val
      }
	  if let txt = try? values.decode(String.self, forKey: .language) {
		language = txt
	  }
    } catch {
      NSLog("*** Error decoding Status: \(error)")
      throw error
    }
  }
}

public struct ReblogStatus: AnyStatus, Decodable, Identifiable, Equatable, Hashable {
  public var viewId: String {
    id + createdAt + (editedAt ?? "")
  }
  
  public static func == (lhs: ReblogStatus, rhs: ReblogStatus) -> Bool {
    lhs.id == rhs.id
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public var id = ""
  public var content = HTMLString(stringValue: "")
  public var account: Account
  public var createdAt: ServerDate
  public var editedAt: ServerDate?
  public var mediaAttachments = [MediaAttachment]()
  public var mentions = [Mention]()
  public var repliesCount = 0
  public var reblogsCount = 0
  public var favouritesCount = 0
  public var card: Card?
  public var favourited = false
  public var reblogged = false
  public var pinned = false
  public var bookmarked = false
  public var emojis = [Emoji]()
  public var url = ""
  public var application: Application?
  public var inReplyToAccountId = ""
  public var visibility: Visibility
  public var poll: Poll?
  public var spoilerText = HTMLString(stringValue: "")
  public var filtered = [Filtered]()
  public var sensitive = false
  public var language = ""

  enum Keys: String, CodingKey {
  	case id, content, account, createdAt, editedAt, mediaAttachments, mentions, repliesCount, reblogsCount, favouritesCount
  	case card, favourited, reblogged, pinned, bookmarked, emojis, url, application, inReplyToAccountId, visibility, poll, spoilerText
  	case filtered, sensitive, language
  }
  
  public init() {
  	id = UUID().uuidString
  	content = HTMLString(stringValue: "This is a #toot\nWith some @content\nAnd some more content for your #eyes @only")
  	account = Account.placeholder()
  	createdAt = "2022-12-16T10:20:54.000Z"
  	visibility = Visibility.pub
	spoilerText = HTMLString(stringValue: "")
  }
  
  public init(from decoder: Decoder) throws {
  	let values = try decoder.container(keyedBy: Keys.self)
  	do {
  		id = try values.decode(String.self, forKey: .id)
  		content = try values.decode(HTMLString.self, forKey: .content)
  		account = try values.decode(Account.self, forKey: .account)
  		createdAt = try values.decode(ServerDate.self, forKey: .createdAt)
  		if let dt = try? values.decode(ServerDate.self, forKey: .editedAt) {
  			editedAt = dt
  		}
  		mediaAttachments = try values.decode([MediaAttachment].self, forKey: .mediaAttachments)
  		mentions = try values.decode([Mention].self, forKey: .mentions)
  		repliesCount = try values.decode(Int.self, forKey: .repliesCount)
  		reblogsCount = try values.decode(Int.self, forKey: .reblogsCount)
  		favouritesCount = try values.decode(Int.self, forKey: .favouritesCount)
  		if let c = try? values.decode(Card.self, forKey: .card) {
  			card = c
  		}
  		favourited = try values.decode(Bool.self, forKey: .favourited)
  		reblogged = try values.decode(Bool.self, forKey: .reblogged)
  		if let val = try? values.decode(Bool.self, forKey: .pinned) {
  			pinned = val
  		}
  		if let val = try? values.decode(Bool.self, forKey: .bookmarked) {
  			bookmarked = val
  		}
  		emojis = try values.decode([Emoji].self, forKey: .emojis)
  		if let u = try? values.decode(String.self, forKey: .url) {
  			url = u
  		}
  		if let app = try? values.decode(Application.self, forKey: .application) {
  			application = app
  		}
  		if let txt = try? values.decode(String.self, forKey: .inReplyToAccountId) {
  			inReplyToAccountId = txt
  		}
  		visibility = try values.decode(Visibility.self, forKey: .visibility)
  		if let p = try? values.decode(Poll.self, forKey: .poll) {
  			poll = p
  		}
  		spoilerText = try values.decode(HTMLString.self, forKey: .spoilerText)
  		if let arr = try? values.decode([Filtered].self, forKey: .filtered) {
  			filtered = arr
  		}
  		if let val = try? values.decode(Bool.self, forKey: .sensitive) {
  			sensitive = val
  		}
		if let txt = try? values.decode(String.self, forKey: .language) {
		  language = txt
		}
  	} catch {
  		NSLog("*** Error decoding ReblogStatus: \(error)")
  		throw error
  	}
  }

}
