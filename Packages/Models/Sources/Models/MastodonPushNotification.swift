import Foundation

public struct MastodonPushNotification: Codable {
  public let accessToken: String

  public let notificationID: Int
  public let notificationType: String

  public let preferredLocale: String?
  public let icon: String?
  public let title: String
  public let body: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case notificationID = "notification_id"
    case notificationType = "notification_type"
    case preferredLocale = "preferred_locale"
    case icon
    case title
    case body
  }
}

extension MastodonPushNotification: Sendable {}
