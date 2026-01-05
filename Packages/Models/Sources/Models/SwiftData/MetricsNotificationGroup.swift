import Foundation
import SwiftData

@Model public class MetricsNotificationGroup {
  public var groupKey: String = ""
  public var type: String = ""
  public var notificationsCount: Int = 0
  public var mostRecentNotificationId: Int = 0
  public var latestPageNotificationAt: Date = Date()
  public var dayStart: Date = Date()
  public var statusId: String = ""
  public var accountId: String = ""
  public var server: String = ""

  public init(
    groupKey: String,
    type: String,
    notificationsCount: Int,
    mostRecentNotificationId: Int,
    latestPageNotificationAt: Date,
    dayStart: Date,
    statusId: String,
    accountId: String,
    server: String
  ) {
    self.groupKey = groupKey
    self.type = type
    self.notificationsCount = notificationsCount
    self.mostRecentNotificationId = mostRecentNotificationId
    self.latestPageNotificationAt = latestPageNotificationAt
    self.dayStart = dayStart
    self.statusId = statusId
    self.accountId = accountId
    self.server = server
  }
}
