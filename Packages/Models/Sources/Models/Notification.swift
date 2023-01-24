import Foundation

public struct Notification: Decodable, Identifiable {
  public enum NotificationType: String, CaseIterable {
    case follow, follow_request, mention, reblog, status, favorite, poll, update
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
          type: NotificationType.favorite.rawValue,
          createdAt: "2022-12-16T10:20:54.000Z",
          account: .placeholder(),
          status: .placeholder())
  }

  public static func placeholders() -> [Notification] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}
