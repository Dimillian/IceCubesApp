import Foundation

public struct StatusHistory: Decodable, Identifiable {
  public var id: String {
    createdAt.asDate.description
  }

  public let content: HTMLString
  public let createdAt: ServerDate
  public let emojis: [Emoji]
}

extension StatusHistory: Sendable {}
