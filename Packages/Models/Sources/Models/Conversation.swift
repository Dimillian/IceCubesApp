import Foundation

public struct Conversation: Identifiable, Decodable, Hashable, Equatable {
  public let id: String
  public let unread: Bool
  public let lastStatus: Status
  public let accounts: [Account]

  public static func placeholder() -> Conversation {
    .init(id: UUID().uuidString, unread: false, lastStatus: .placeholder(), accounts: [.placeholder()])
  }

  public static func placeholders() -> [Conversation] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
     .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}
