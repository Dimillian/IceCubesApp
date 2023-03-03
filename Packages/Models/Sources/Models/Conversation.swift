import Foundation

public struct Conversation: Identifiable, Decodable, Hashable, Equatable {
  public let id: String
  public let unread: Bool
  public let lastStatus: Status?
  public let accounts: [Account]

  public init(id: String, unread: Bool, lastStatus: Status? = nil, accounts: [Account]) {
    self.id = id
    self.unread = unread
    self.lastStatus = lastStatus
    self.accounts = accounts
  }

  public static func placeholder() -> Conversation {
    .init(id: UUID().uuidString, unread: false, lastStatus: .placeholder(), accounts: [.placeholder()])
  }

  public static func placeholders() -> [Conversation] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
     .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}

extension Conversation: Sendable {}
