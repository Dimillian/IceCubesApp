import Foundation
import HTML2Markdown
import SwiftSoup
import SwiftUI

public struct HTMLString: Decodable, Equatable, Hashable {
  public let htmlValue: String
  public let asMarkdown: String
  public let asRawText: String
  public let statusesURLs: [URL]
  public let asSafeMarkdownAttributedString: AttributedString

  public init(from decoder: Decoder) {
    do {
      let container = try decoder.singleValueContainer()
      htmlValue = try container.decode(String.self)
    } catch {
      htmlValue = ""
    }

    do {
      asMarkdown = try HTMLParser().parse(html: htmlValue)
        .toMarkdown()
        .replacingOccurrences(of: ")[", with: ") [")
    } catch {
      asMarkdown = htmlValue
    }

    var statusesURLs: [URL] = []
    do {
      let document: Document = try SwiftSoup.parse(htmlValue)
      let links: Elements = try document.select("a")
      for link in links {
        let href = try link.attr("href")
        if let url = URL(string: href),
           let _ = Int(url.lastPathComponent)
        {
          statusesURLs.append(url)
        }
      }
      asRawText = try document.text()
    } catch {
      asRawText = htmlValue
    }

    self.statusesURLs = statusesURLs

    do {
      let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true,
                                                            interpretedSyntax: .inlineOnlyPreservingWhitespace)
      asSafeMarkdownAttributedString = try AttributedString(markdown: asMarkdown, options: options)
    } catch {
      asSafeMarkdownAttributedString = AttributedString(stringLiteral: htmlValue)
    }
  }

  public init(stringValue: String) {
    htmlValue = stringValue
    asMarkdown = stringValue
    asRawText = stringValue
    statusesURLs = []
    asSafeMarkdownAttributedString = AttributedString(stringLiteral: htmlValue)
  }
}
