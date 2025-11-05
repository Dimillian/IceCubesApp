//
//  ConsolidatedNotification.swift
//
//
//  Created by Jérôme Danthinne on 31/01/2023.
//

import Foundation

public struct ConsolidatedNotification: Identifiable {
  public let notifications: [Notification]
  public let type: Notification.NotificationType
  public let createdAt: ServerDate
  public let accounts: [Account]
  public let status: Status?
  public let mostRecentNotificationId: String

  public var id: String { groupKey ?? mostRecentNotificationId }
  
  // For V2 API compatibility
  public var groupKey: String?

  public init(
    notifications: [Notification],
    mostRecentNotificationId: String,
    type: Notification.NotificationType,
    createdAt: ServerDate,
    accounts: [Account],
    status: Status?,
    groupKey: String? = nil
  ) {
    self.notifications = notifications
    self.type = type
    self.createdAt = createdAt
    self.accounts = accounts
    self.status = status ?? nil
    self.groupKey = groupKey
    self.mostRecentNotificationId = mostRecentNotificationId
  }

  public static func placeholder() -> ConsolidatedNotification {
    .init(
      notifications: [Notification.placeholder()],
      mostRecentNotificationId: UUID().uuidString,
      type: .favourite,
      createdAt: ServerDate(),
      accounts: [.placeholder()],
      status: .placeholder())
  }

  public static func placeholders() -> [ConsolidatedNotification] {
    [
      .placeholder(), .placeholder(), .placeholder(),
      .placeholder(), .placeholder(), .placeholder(),
      .placeholder(), .placeholder(), .placeholder(),
      .placeholder(), .placeholder(), .placeholder(),
    ]
  }
}

extension ConsolidatedNotification: Sendable {}
