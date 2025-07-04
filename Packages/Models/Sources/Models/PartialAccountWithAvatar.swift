import Foundation

public struct PartialAccountWithAvatar: Codable, Identifiable, Sendable {
  public let id: String
  public let acct: String
  public let url: String
  public let avatar: String
  public let avatarStatic: String
  public let locked: Bool
  public let bot: Bool
  
  public init(
    id: String,
    acct: String,
    url: String,
    avatar: String,
    avatarStatic: String,
    locked: Bool,
    bot: Bool
  ) {
    self.id = id
    self.acct = acct
    self.url = url
    self.avatar = avatar
    self.avatarStatic = avatarStatic
    self.locked = locked
    self.bot = bot
  }
}