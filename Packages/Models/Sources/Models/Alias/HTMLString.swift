import Foundation
import SwiftSoup
import SwiftUI

private enum CodingKeys: CodingKey {
  case htmlValue, asMarkdown, asRawText, statusesURLs
}

public struct HTMLString: Codable, Equatable, Hashable, @unchecked Sendable {
  public var htmlValue: String = ""
  public var asMarkdown: String = ""
  public var asRawText: String = ""
  public var statusesURLs = [URL]()
  public var links = [Link]()

  public var asSafeMarkdownAttributedString: AttributedString = .init()
  private var main_regex: NSRegularExpression?
  private var underscore_regex: NSRegularExpression?
  public init(from decoder: Decoder) {
    var alreadyDecoded = false
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
      main_regex = try? NSRegularExpression(pattern: "([\\*\\`\\[\\\\])", options: .caseInsensitive)
      // don't escape underscores that are between colons, they are most likely custom emoji
      underscore_regex = try? NSRegularExpression(pattern: "(?!\\B:[^:]*)(_)(?![^:]*:\\B)", options: .caseInsensitive)

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

    /// This somehow crash in some cases.
    /// Disabling for now
    /// Could be related to this: https://github.com/apple/swift/issues/61532
    /*
    links = asSafeMarkdownAttributedString.runs
      .compactMap { run in
        guard let link = run.link else {
          return nil
        }

        return Link(link, displayString: String(self.asSafeMarkdownAttributedString[run.range].characters))
      }
     */
  }

  public init(stringValue: String, parseMarkdown: Bool = false) {
    htmlValue = stringValue
    asMarkdown = stringValue
    asRawText = stringValue
    statusesURLs = []

    if parseMarkdown {
      do {
        let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true,
                                                              interpretedSyntax: .inlineOnlyPreservingWhitespace)
        asSafeMarkdownAttributedString = try AttributedString(markdown: asMarkdown, options: options)
      } catch {
        asSafeMarkdownAttributedString = AttributedString(stringLiteral: htmlValue)
      }
    } else {
      asSafeMarkdownAttributedString = AttributedString(stringLiteral: htmlValue)
    }

    /*
    links = asSafeMarkdownAttributedString.runs
      .compactMap { run in
        guard let link = run.link else {
          return nil
        }

        return Link(link, displayString: String(self.asSafeMarkdownAttributedString[run.range].characters))
      }
     */
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
          asMarkdown += "\n"
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

        if let underscore_regex, let main_regex {
          //  This is the markdown escaper
          txt = main_regex.stringByReplacingMatches(in: txt, options: [], range: NSRange(location: 0, length: txt.count), withTemplate: "\\\\$1")
          txt = underscore_regex.stringByReplacingMatches(in: txt, options: [], range: NSRange(location: 0, length: txt.count), withTemplate: "\\\\$1")
        }
        // Strip newlines and line separators - they should be being sent as <br>s
        asMarkdown += txt.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\u{2028}", with: "")
      }

      for n in node.getChildNodes() {
        handleNode(node: n)
      }
    } catch {}
  }

  public struct Link: Hashable, Identifiable {
    public var id: Int { hashValue }
    public let url: AttributeScopes.FoundationAttributes.LinkAttribute.Value
    public let displayString: String
    public let type: LinkType
    public let title: String

    init(_ url: AttributeScopes.FoundationAttributes.LinkAttribute.Value, displayString: String) {
      self.url = url
      self.displayString = displayString

      switch displayString.first {
        case "@":
          self.type = .mention
          self.title = displayString
        case "#":
          self.type = .hashtag
          self.title = String(displayString.dropFirst())
        default:
          self.type = .url
          var hostNameUrl = url.host ?? url.absoluteString
          if hostNameUrl.hasPrefix("www.") {
            hostNameUrl = String(hostNameUrl.dropFirst(4))
          }
          self.title = hostNameUrl
      }
    }

    public enum LinkType {
      case url
      case mention
      case hashtag
    }
  }
}
