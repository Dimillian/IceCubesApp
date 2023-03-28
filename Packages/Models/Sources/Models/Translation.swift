import Foundation

public struct Translation: Decodable {
  public let content: HTMLString
  public let detectedSourceLanguage: String
  public let provider: String

  public init(content: String, detectedSourceLanguage: String, provider: String) {
    self.content = .init(stringValue: content)
    self.detectedSourceLanguage = detectedSourceLanguage
    self.provider = provider
  }
}

extension Translation: Sendable {}
