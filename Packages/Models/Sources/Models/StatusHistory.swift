import Foundation

public struct StatusHistory: Decodable, Identifiable {
  public var id: String {
    createdAt.description
  }

  public let content: HTMLString
  public let createdAt: ServerDate
  public let emojis: [Emoji]
}
