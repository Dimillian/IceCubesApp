import Foundation
import HTML2Markdown
import SwiftUI

public typealias HTMLString = String

extension HTMLString {
  public var asMarkdown: String {
    do {
      let dom = try HTMLParser().parse(html: self)
      return dom.toMarkdown()
    } catch {
      return self
    }
  }
  
  public var asSafeAttributedString: AttributedString {
    do {
      let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true,
                                                            interpretedSyntax: .inlineOnlyPreservingWhitespace)
      return try AttributedString(markdown: asMarkdown, options: options)
    } catch {
      return AttributedString(stringLiteral: self)
    }
  }
}

