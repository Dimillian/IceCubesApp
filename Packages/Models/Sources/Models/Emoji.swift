import Foundation

public struct Emoji: Codable, Hashable, Identifiable, Equatable, Sendable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(shortcode)
  }

  public var id: String {
    shortcode
  }

  public let shortcode: String
  public let url: URL
  public let staticUrl: URL
  public let visibleInPicker: Bool
  public let category: String?
}
