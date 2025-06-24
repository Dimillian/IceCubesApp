import Foundation

public struct GroupedNotificationsResults: Codable, Sendable {
  public let accounts: [Account]
  public let partialAccounts: [PartialAccountWithAvatar]?
  public let statuses: [Status]
  public let notificationGroups: [NotificationGroup]
  
  public init(
    accounts: [Account],
    partialAccounts: [PartialAccountWithAvatar]? = nil,
    statuses: [Status],
    notificationGroups: [NotificationGroup]
  ) {
    self.accounts = accounts
    self.partialAccounts = partialAccounts
    self.statuses = statuses
    self.notificationGroups = notificationGroups
  }
}