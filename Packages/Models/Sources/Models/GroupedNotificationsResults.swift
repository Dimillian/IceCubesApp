import Foundation

public struct GroupedNotificationsResults: Codable, Sendable {
  public let accounts: [Account]
  public let statuses: [Status]
  public let notificationGroups: [NotificationGroup]
  
  public init(
    accounts: [Account],
    statuses: [Status],
    notificationGroups: [NotificationGroup]
  ) {
    self.accounts = accounts
    self.statuses = statuses
    self.notificationGroups = notificationGroups
  }
}
