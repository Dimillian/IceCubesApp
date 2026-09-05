import Foundation

public struct NotificationGroup: Codable, Identifiable, Sendable {
  public let groupKey: String
  public let notificationsCount: Int
  public let type: String
  public let mostRecentNotificationId: Int
  public let pageMinId: String?
  public let pageMaxId: String?
  public let latestPageNotificationAt: ServerDate
  public let sampleAccountIds: [String]
  public let statusId: String?
  /// Attached when `type` is `added_to_collection` or `collection_update` (Mastodon 4.6+).
  public let collection: AccountCollection?
  
  public var id: String { groupKey }
}
