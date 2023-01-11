import Foundation
import EmojiText
import Models
import HTML2Markdown

public extension EmojiText {
    init(_ string: HTMLString, emojis: [Emoji]) {
        let markdown = string.asMarkdown
        self.init(markdown: markdown, emojis: emojis.map { RemoteEmoji(shortcode: $0.shortcode, url: $0.url) })
    }
}
