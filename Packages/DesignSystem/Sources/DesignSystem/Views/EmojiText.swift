import EmojiText
import Foundation
import HTML2Markdown
import Models
import SwiftUI

public struct EmojiTextApp: View {
  private let markdown: HTMLString
  private let emojis: [any CustomEmoji]
  private let language: String?
  private let append: (() -> Text)?

  public init(_ markdown: HTMLString, emojis: [Emoji], language: String? = nil, append: (() -> Text)? = nil) {
    self.markdown = markdown
    self.emojis = emojis.map { RemoteEmoji(shortcode: $0.shortcode, url: $0.url) }
    self.language = language
    self.append = append
  }

  public var body: some View {
    if let append {
      EmojiText(markdown: markdown.asMarkdown, emojis: emojis)
        .append {
          append()
        }
    } else if emojis.isEmpty {
      Text(markdown.asSafeMarkdownAttributedString)
        .environment(\.layoutDirection, isRTL() ? .rightToLeft : .leftToRight)
    } else {
      EmojiText(markdown: markdown.asMarkdown, emojis: emojis)
        .environment(\.layoutDirection, isRTL() ? .rightToLeft : .leftToRight)
    }
  }

  private func isRTL() -> Bool {
    // Arabic, Hebrew, Persian, Urdu, Kurdish, Azeri, Dhivehi
    return ["ar", "he", "fa", "ur", "ku", "az", "dv"].contains(language)
  }
}
