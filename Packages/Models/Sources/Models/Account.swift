import Foundation

public struct Account: Decodable, Identifiable, Equatable, Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public struct Field: Decodable, Equatable, Identifiable {
    public var id: String {
      value.asRawText + name
    }

    public let name: String
    public let value: HTMLString
    public let verifiedAt: String?
  }

  public struct Source: Decodable, Equatable {
    public let privacy: Visibility
    public let sensitive: Bool
    public let language: String?
    public let note: String
    public let fields: [Field]
  }

  public var id = ""
  public var username = ""
  public var displayName = ""
  public var avatar: URL!
  public var header: URL!
  public var acct = ""
  public var note: HTMLString!
  public var createdAt: ServerDate!
  public var followersCount = 0
  public var followingCount = 0
  public var statusesCount = 0
  public var lastStatusAt: String?
  public var fields = [Field]()
  public var locked = false
  public var emojis = [Emoji]()
  public var url: URL?
  public var source: Source?
  public var bot = false
  public var discoverable = true
  
  public static func placeholder() -> Account {
    var a = Account()
    a.id = UUID().uuidString
    a.username = "Username"
    a.displayName = "Display Name"
    a.avatar = URL(string: "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png")!
    a.header = URL(string: "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png")!
    a.acct = "account@account.com"
    a.note = HTMLString(stringValue: "Some note")
    a.createdAt = "2022-12-16T10:20:54.000Z"
    a.followersCount = 10
    a.followingCount = 10
    a.statusesCount = 10
    return a
  }

  public static func placeholders() -> [Account] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
     .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
  
  enum CodingKeys: String, CodingKey {
    case id, username, displayName, avatar, header, acct, note, createdAt, followersCount, followingCount, statusesCount
    case lastStatusAt, fields, locked, emojis, url, source, bot, discoverable
  }

  init() {
    
  }
  
  public init(from decoder: Decoder) throws {
    do {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      username = try values.decode(String.self, forKey: .username)
      displayName = try values.decode(String.self, forKey: .displayName)
      avatar = try values.decode(URL.self, forKey: .avatar)
      header = try values.decode(URL.self, forKey: .header)
      acct = try values.decode(String.self, forKey: .acct)
      note = try values.decode(HTMLString.self, forKey: .note)
      createdAt = try values.decode(ServerDate.self, forKey: .createdAt)
      followersCount = try values.decode(Int.self, forKey: .followersCount)
      followingCount = try values.decode(Int.self, forKey: .followingCount)
      statusesCount = try values.decode(Int.self, forKey: .statusesCount)
      if let txt = try? values.decode(String.self, forKey: .lastStatusAt) {
        lastStatusAt = txt
      }
      if let arr = try? values.decode([Field].self, forKey: .fields) {
        fields = arr
      }
      if let val = try? values.decode(Bool.self, forKey: .locked) {
        locked = val
      }
      if let arr = try? values.decode([Emoji].self, forKey: .emojis) {
        emojis = arr
      }
      if let u = try? values.decode(URL.self, forKey: .url) {
        url = u
      }
      if let s = try? values.decode(Source.self, forKey: .source) {
        source = s
      }
      if let val = try? values.decode(Bool.self, forKey: .bot) {
        bot = val
      }
      if let val = try? values.decode(Bool.self, forKey: .discoverable) {
        discoverable = val
      }
    } catch {
      NSLog("*** Error decoding Account: \(error)")
      throw error
    }
  }
}

public struct FamiliarAccounts: Decodable {
  public let id: String
  public let accounts: [Account]
}
