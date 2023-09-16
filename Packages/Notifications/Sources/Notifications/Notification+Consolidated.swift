//
//  Notification+Consolidated.swift
//
//
//  Created by Jérôme Danthinne on 31/01/2023.
//

import Foundation
import Models

extension [Models.Notification] {
  func consolidated(selectedType: Models.Notification.NotificationType?) async -> [ConsolidatedNotification] {
    await withCheckedContinuation { result in
      DispatchQueue.global().async {
        let notifications: [ConsolidatedNotification] =
          Dictionary(grouping: self) { $0.consolidationId(selectedType: selectedType) }
            .values
            .compactMap { notifications in
              guard let notification = notifications.first,
                    let supportedType = notification.supportedType
              else { return nil }

              return ConsolidatedNotification(notifications: notifications,
                                              type: supportedType,
                                              createdAt: notification.createdAt,
                                              accounts: notifications.map(\.account),
                                              status: notification.status)
            }
            .sorted {
              $0.createdAt.asDate > $1.createdAt.asDate
            }
        result.resume(returning: notifications)
      }
    }
  }
}
