import Foundation

public struct Notification: Codable, Identifiable {
  public enum NotificationType: String {
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
          createdAt: "2022-12-16T10:20:54.000Z",
          account: .placeholder(),
          status: .placeholder())
  }
  
  public static func placeholders() -> [Notification] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}

