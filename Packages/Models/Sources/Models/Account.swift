import Foundation

public struct Account: Codable, Identifiable, Equatable, Hashable {
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  public struct Field: Codable, Equatable, Identifiable {
    public var id: String {
      value + name
    }
    
    public let name: String
    public let value: HTMLString
    public let verifiedAt: String?
  }
  
  public struct Source: Codable, Equatable {
    public let privacy: Visibility
    public let sensitive: Bool
    public let language: String?
    public let note: String
    public let fields: [Field]
  }
  
  public let id: String
  public let username: String
  public let displayName: String
  public let avatar: URL
  public let header: URL
  public let acct: String
  public let note: HTMLString
  public let createdAt: ServerDate
  public let followersCount: Int
  public let followingCount: Int
  public let statusesCount: Int
  public let lastStatusAt: String?
  public let fields: [Field]
  public let locked: Bool
  public let emojis: [Emoji]
  public let url: URL?
  public let source: Source?
  public let bot: Bool
  public let discoverable: Bool?
  
  public static func placeholder() -> Account {
    .init(id: UUID().uuidString,
          username: "Username",
          displayName: "Display Name",
          avatar: URL(string: "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png")!,
          header: URL(string: "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png")!,
          acct: "account@account.com",
          note: "Some content",
          createdAt: "2022-12-16T10:20:54.000Z",
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

public struct FamilliarAccounts: Codable {
  public let id: String
  public let accounts: [Account]
}
