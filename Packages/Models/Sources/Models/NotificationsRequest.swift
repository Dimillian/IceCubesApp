import Foundation

public struct NotificationsRequest: Identifiable, Decodable, Sendable {
  public let id: String
  public let account: Account
  public let notificationsCount: String
}
