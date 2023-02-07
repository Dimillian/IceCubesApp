import Foundation
import SwiftSoup
import SwiftUI

fileprivate enum CodingKeys: CodingKey {
  case htmlValue, asMarkdown, asRawText, statusesURLs
}

public struct HTMLString: Codable, Equatable, Hashable {
  public var htmlValue: String = ""
  public var asMarkdown: String = ""
  public var asRawText: String = ""
  public var statusesURLs = [URL]()
  
  public var asSafeMarkdownAttributedString: AttributedString = .init()
  private var regex: NSRegularExpression?
  
  public init(from decoder: Decoder) {
    var alreadyDecoded: Bool = false
    do {
      let container = try decoder.singleValueContainer()
      htmlValue = try container.decode(String.self)
    } catch {
      do {
        alreadyDecoded = true
        let container = try decoder.container(keyedBy: CodingKeys.self)
        htmlValue = try container.decode(String.self, forKey: .htmlValue)
        asMarkdown = try container.decode(String.self, forKey: .asMarkdown)
        asRawText = try container.decode(String.self, forKey: .asRawText)
        statusesURLs = try container.decode([URL].self, forKey: .statusesURLs)
      } catch {
        htmlValue = ""
      }
    }

    if !alreadyDecoded {
      // https://daringfireball.net/projects/markdown/syntax
      // Pre-escape \ ` _ * and [ as these are the only
      // characters the markdown parser used picks up
      // when it renders to attributed text
      regex = try? NSRegularExpression(pattern: "([\\_\\*\\`\\[\\\\])", options: .caseInsensitive)

      asMarkdown = ""
      do {
        let document: Document = try SwiftSoup.parse(htmlValue)
        handleNode(node: document)

        document.outputSettings(OutputSettings().prettyPrint(pretty: false))
        try document.select("br").after("\n")
        try document.select("p").after("\n\n")
        let html = try document.html()
        var text = try SwiftSoup.clean(html, "", Whitelist.none(), OutputSettings().prettyPrint(pretty: false)) ?? ""
        // Remove the two last line break added after the last paragraph.
        if text.hasSuffix("\n\n") {
          _ = text.removeLast()
          _ = text.removeLast()
        }
        asRawText = text

        if asMarkdown.hasPrefix("\n") {
          _ = asMarkdown.removeFirst()
        }

      } catch {
        asRawText = htmlValue
      }
    }
    
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

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(htmlValue, forKey: .htmlValue)
    try container.encode(asMarkdown, forKey: .asMarkdown)
    try container.encode(asRawText, forKey: .asRawText)
    try container.encode(statusesURLs, forKey: .statusesURLs)
  }

  private mutating func handleNode(node: SwiftSoup.Node) {
    do {
      if let className = try? node.attr("class") {
        if className == "invisible" {
          // don't display
          return
        }

        if className == "ellipsis" {
          // descend into this one now and
          // append the ellipsis
          for nn in node.getChildNodes() {
            handleNode(node: nn)
          }
          asMarkdown += "…"
          return
        }
      }

      if node.nodeName() == "p" {
        if asMarkdown.count > 0 { // ignore first opening <p>
          asMarkdown += "\n\n"
        }
      } else if node.nodeName() == "br" {
        if asMarkdown.count > 0 { // ignore first opening <br>
          // some code to try and stop double carriage rerturns where they aren't required
          // not perfect but effective in almost all cases
          if !asMarkdown.hasSuffix("\n") && !asMarkdown.hasSuffix("\u{2028}") {
            if let next = node.nextSibling() {
              if next.nodeName() == "#text" && (next.description.hasPrefix("\n") || next.description.hasPrefix("\u{2028}")) {
                // do nothing
              } else {
                asMarkdown += "\n"
              }
            }
          }
        }
      } else if node.nodeName() == "a" {
        let href = try node.attr("href")
        if href != "" {
          if let url = URL(string: href),
             let _ = Int(url.lastPathComponent)
          {
            statusesURLs.append(url)
          }
        }
        asMarkdown += "["
        // descend into this node now so we can wrap the
        // inner part of the link in the right markup
        for nn in node.getChildNodes() {
          handleNode(node: nn)
        }
        asMarkdown += "]("
        asMarkdown += href
        asMarkdown += ")"
        return
      } else if node.nodeName() == "#text" {
        var txt = node.description

        if let regex {
          //  This is the markdown escaper
          txt = regex.stringByReplacingMatches(in: txt, options: [], range: NSRange(location: 0, length: txt.count), withTemplate: "\\\\$1")
        }

        asMarkdown += txt
      }

      for n in node.getChildNodes() {
        handleNode(node: n)
      }
    } catch {}
  }
}
