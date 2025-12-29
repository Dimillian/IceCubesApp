import EmojiText
import Env
import Foundation
import Models
import SwiftUI

@MainActor
public struct EmojiTextApp: View {
  private let markdown: HTMLString
  private let emojis: [any CustomEmoji]
  private let language: String?
  private let append: (@Sendable () -> Text)?
  private let lineLimit: Int?

  public init(
    _ markdown: HTMLString, emojis: [Emoji], language: String? = nil, lineLimit: Int? = nil,
    append: (@Sendable () -> Text)? = nil
  ) {
    self.markdown = markdown
    self.emojis = emojis.map { RemoteEmoji(shortcode: $0.shortcode, url: $0.url) }
    self.language = language
    self.lineLimit = lineLimit
    self.append = append
  }

  public var body: some View {
    if let append {
      EmojiText(markdown: markdown.asMarkdown, emojis: emojis)
        .animated(UserPreferences.shared.animateEmojis)
        .append(text: append)
        .lineLimit(lineLimit)
    } else if emojis.isEmpty {
      Text(markdown.asSafeMarkdownAttributedString)
        .lineLimit(lineLimit)
        .environment(\.layoutDirection, isRTL() ? .rightToLeft : .leftToRight)
    } else {
      EmojiText(markdown: markdown.asMarkdown, emojis: emojis)
        .animated(UserPreferences.shared.animateEmojis)
        .lineLimit(lineLimit)
        .environment(\.layoutDirection, isRTL() ? .rightToLeft : .leftToRight)
    }
  }

  private func isRTL() -> Bool {
    // Arabic, Hebrew, Persian, Urdu, Kurdish, Azeri, Dhivehi
    ["ar", "he", "fa", "ur", "ku", "az", "dv"].contains(language)
  }
}
