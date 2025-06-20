import Foundation

public struct NotificationGroup: Codable, Identifiable, Sendable {
  public let groupKey: String
  public let notificationsCount: Int
  public let type: String
  public let mostRecentNotificationId: Int
  public let pageMinId: String?
  public let pageMaxId: String?
  public let latestPageNotificationAt: String?
  public let sampleAccountIds: [String]
  public let statusId: String?
  
  public var id: String { groupKey }
  
  public init(
    groupKey: String,
    notificationsCount: Int,
    type: String,
    mostRecentNotificationId: Int,
    pageMinId: String? = nil,
    pageMaxId: String? = nil,
    latestPageNotificationAt: String? = nil,
    sampleAccountIds: [String],
    statusId: String? = nil
  ) {
    self.groupKey = groupKey
    self.notificationsCount = notificationsCount
    self.type = type
    self.mostRecentNotificationId = mostRecentNotificationId
    self.pageMinId = pageMinId
    self.pageMaxId = pageMaxId
    self.latestPageNotificationAt = latestPageNotificationAt
    self.sampleAccountIds = sampleAccountIds
    self.statusId = statusId
  }
}