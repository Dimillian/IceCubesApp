import Foundation

public protocol AnyStatus {
  var id: String { get }
  var content: HTMLString { get }
  var account: Account { get }
  var createdAt: String { get }
  var mediaAttachments: [MediaAttachement] { get }
  var mentions: [Mention] { get }
  var repliesCount: Int { get }
  var reblogsCount: Int { get }
  var favouritesCount: Int { get }
  var card: Card? { get }
  var favourited: Bool { get }
  var reblogged: Bool { get }
  var pinned: Bool? { get }
  var emojis: [Emoji] { get }
}

public struct Status: AnyStatus, Codable, Identifiable {
  public let id: String
  public let content: HTMLString
  public let account: Account
  public let createdAt: ServerDate
  public let reblog: ReblogStatus?
  public let mediaAttachments: [MediaAttachement]
  public let mentions: [Mention]
  public let repliesCount: Int
  public let reblogsCount: Int
  public let favouritesCount: Int
  public let card: Card?
  public let favourited: Bool
  public let reblogged: Bool
  public let pinned: Bool?
  public let emojis: [Emoji]
  
  public static func placeholder() -> Status {
    .init(id: UUID().uuidString,
          content: "Some post content\n Some more post content \n Some more",
          account: .placeholder(),
          createdAt: "2022-12-16T10:20:54.000Z",
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
          emojis: [])
  }
  
  public static func placeholders() -> [Status] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}

public struct ReblogStatus: AnyStatus, Codable, Identifiable {
  public let id: String
  public let content: String
  public let account: Account
  public let createdAt: String
  public let mediaAttachments: [MediaAttachement]
  public let mentions: [Mention]
  public let repliesCount: Int
  public let reblogsCount: Int
  public let favouritesCount: Int
  public let card: Card?
  public let favourited: Bool
  public let reblogged: Bool
  public let pinned: Bool?
  public let emojis: [Emoji]
}
