import Foundation

public struct Notification: Decodable, Identifiable, Equatable {
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

  public static func placeholder() -> Notification {
    .init(id: UUID().uuidString,
          type: NotificationType.favourite.rawValue,
          createdAt: ServerDate(),
          account: .placeholder(),
          status: .placeholder())
  }
}

extension Notification: Sendable {}
extension Notification.NotificationType: Sendable {}
