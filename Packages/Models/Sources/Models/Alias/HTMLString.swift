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
  
  public func findStatusesIds(instance: String) -> [Int]? {
    do {
      let document: Document = try SwiftSoup.parse(self)
      let links: Elements = try document.select("a")
      var ids: [Int] = []
      for link in links {
        let href = try link.attr("href")
        if href.contains(instance.lowercased()),
           let url = URL(string: href),
            let statusId = Int(url.lastPathComponent) {
          ids.append(statusId)
        }
      }
      return ids
    } catch {
      return nil
    }
  }
  
  public var asSafeAttributedString: AttributedString {
    do {
      // Add space between hashtags and mentions that follow each other
      let markdown = asMarkdown
        .replacingOccurrences(of: ")[", with: ") [")
      let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true,
                                                            interpretedSyntax: .inlineOnlyPreservingWhitespace)
      return try AttributedString(markdown: markdown, options: options)
    } catch {
      return AttributedString(stringLiteral: self)
    }
  }
}

