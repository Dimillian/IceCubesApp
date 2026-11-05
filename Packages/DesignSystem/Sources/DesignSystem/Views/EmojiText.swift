import EmojiText
import Env
import Foundation
import Models
import SwiftUI

@MainActor
public struct EmojiTextApp: View {
  /// Above this many custom emoji in one text, the emoji are shown as their shortcodes.
  /// Every inline emoji image adds levels of Text concatenation that SwiftUI resolves
  /// recursively, and a post with a few hundred emoji overflows the main thread stack
  /// on device. The crash starts between 300 and 350 emoji with the 1 MB stack of an
  /// iPhone, so this keeps a wide margin.
  private static let maxInlineEmojis = 100

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
    if Self.emojiCount(in: markdown.asMarkdown, emojis: emojis) > Self.maxInlineEmojis {
      self.emojis = []
    } else {
      self.emojis = emojis.map { RemoteEmoji(shortcode: $0.shortcode, url: $0.url) }
    }
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

  private static func emojiCount(in markdown: String, emojis: [Emoji]) -> Int {
    var count = 0
    for emoji in emojis {
      count += markdown.components(separatedBy: ":\(emoji.shortcode):").count - 1
      if count > maxInlineEmojis {
        break
      }
    }
    return count
  }

  private func isRTL() -> Bool {
    // Arabic, Hebrew, Persian, Urdu, Kurdish, Azeri, Dhivehi
    ["ar", "he", "fa", "ur", "ku", "az", "dv"].contains(language)
  }
}
