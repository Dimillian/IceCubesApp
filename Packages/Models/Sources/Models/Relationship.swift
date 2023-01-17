import Foundation

public struct Relationship: Codable {
  public let id: String
  public let following: Bool
  public let showingReblogs: Bool
  public let followedBy: Bool
  public let blocking: Bool
  public let blockedBy: Bool
  public let muting: Bool
  public let mutingNotifications: Bool
  public let requested: Bool
  public let domainBlocking: Bool
  public let endorsed: Bool
  public let note: String
  public let notifying: Bool

  public static func placeholder() -> Relationship {
    .init(id: UUID().uuidString,
          following: false,
          showingReblogs: false,
          followedBy: false,
          blocking: false,
          blockedBy: false,
          muting: false,
          mutingNotifications: false,
          requested: false,
          domainBlocking: false,
          endorsed: false,
          note: "",
          notifying: false)
  }
}
