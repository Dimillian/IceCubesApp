import EmojiText
import Foundation
import HTML2Markdown
import Models
import SwiftUI

public struct EmojiTextApp: View {
  private let markdown: String
  private let emojis: [any CustomEmoji]
  private let append: (() -> Text)?

  public init(_ markdown: HTMLString, emojis: [Emoji], append: (() -> Text)? = nil) {
    self.markdown = markdown
    self.emojis = emojis.map { RemoteEmoji(shortcode: $0.shortcode, url: $0.url) }
    self.append = append
  }

  public var body: some View {
    if let append {
      EmojiText(markdown: markdown, emojis: emojis)
        .append {
          append()
        }
    } else if emojis.isEmpty {
      Text(markdown.asSafeAttributedString)
    } else {
      EmojiText(markdown: markdown, emojis: emojis)
    }
  }
}
