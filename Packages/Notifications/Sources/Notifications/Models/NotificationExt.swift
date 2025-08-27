//
//  NotificationExt.swift
//
//
//  Created by Jérôme Danthinne on 31/01/2023.
//

import Models

extension Notification {
  func consolidationId(selectedType: Models.Notification.NotificationType?) -> String? {
    guard let supportedType else { return nil }

    switch supportedType {
    case .follow where selectedType != .follow:
      // Always group followers, so use the type to group
      return supportedType.rawValue
    case .reblog, .favourite:
      // Group boosts and favourites by status, so use the type + the related status id
      return "\(supportedType.rawValue)-\(status?.id ?? "")"
    default:
      // Never group remaining ones, so use the notification id itself
      return id
    }
  }

  func isConsolidable(selectedType: Models.Notification.NotificationType?) -> Bool {
    // Notification is consolidable onlt if the consolidation id is not the notication id (unique) itself
    consolidationId(selectedType: selectedType) != id
  }
}
