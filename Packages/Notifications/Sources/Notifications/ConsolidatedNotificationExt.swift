//
//  ConsolidatedNotificationExt.swift
//
//
//  Created by Jérôme Danthinne on 31/01/2023.
//

import Models

extension ConsolidatedNotification {
  var notificationIds: [String] { notifications.map(\.id) }
}

extension [ConsolidatedNotification] {
  var notificationCount: Int {
    reduce(0) { $0 + ($1.accounts.isEmpty ? 1 : $1.accounts.count) }
  }
}
