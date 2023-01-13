import Foundation
import HTML2Markdown
import SwiftSoup
import SwiftUI

public typealias HTMLString = String

extension HTMLString {
  public var asMarkdown: String {
    do {
      let dom = try HTMLParser().parse(html: self)
      return dom.toMarkdown()
        // Add space between hashtags and mentions that follow each other
        .replacingOccurrences(of: ")[", with: ") [")
    } catch {
      return self
    }
  }
  
  public var asRawText: String {
    do {
      let document: Document = try SwiftSoup.parse(self)
      return try document.text()
    } catch {
      return self
    }
  }
  
  public func findStatusesURLs() -> [URL]? {
    do {
      let document: Document = try SwiftSoup.parse(self)
      let links: Elements = try document.select("a")
      var URLs: [URL] = []
      for link in links {
        let href = try link.attr("href")
        if let url = URL(string: href),
            let _ = Int(url.lastPathComponent) {
          URLs.append(url)
        }
      }
      return URLs
    } catch {
      return nil
    }
  }
  
  public var asSafeAttributedString: AttributedString {
    do {
      let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true,
                                                            interpretedSyntax: .inlineOnlyPreservingWhitespace)
      return try AttributedString(markdown: self, options: options)
    } catch {
      return AttributedString(stringLiteral: self)
    }
  }
}

