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

  public var id: String? { notifications.first?.id }

  public init(notifications: [Notification],
              type: Notification.NotificationType,
              createdAt: ServerDate,
              accounts: [Account],
              status: Status?)
  {
    self.notifications = notifications
    self.type = type
    self.createdAt = createdAt
    self.accounts = accounts
    self.status = status ?? nil
  }

  public static func placeholder() -> ConsolidatedNotification {
    .init(notifications: [Notification.placeholder()],
          type: .favourite,
          createdAt: ServerDate(),
          accounts: [.placeholder()],
          status: .placeholder())
  }

  public static func placeholders() -> [ConsolidatedNotification] {
    [.placeholder(), .placeholder(), .placeholder(),
     .placeholder(), .placeholder(), .placeholder(),
     .placeholder(), .placeholder(), .placeholder(),
     .placeholder(), .placeholder(), .placeholder()]
  }
}

extension ConsolidatedNotification: Sendable {}
