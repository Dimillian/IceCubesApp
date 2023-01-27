import Foundation

public struct Notification: Decodable, Identifiable {
  public enum NotificationType: String, CaseIterable {
    case follow, follow_request, mention, reblog, status, favourite, poll, update
  }

  public let id: String
  public let type: String
  public let createdAt: ServerDate
  public let account: Account
  public let status: Status?

  public var supportedType: NotificationType? {
    .init(rawValue: type)
  }
}
