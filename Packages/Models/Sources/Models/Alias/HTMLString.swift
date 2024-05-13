import Foundation
import SwiftSoup
import SwiftUI

private enum CodingKeys: CodingKey {
  case htmlValue, asMarkdown, asRawText, statusesURLs, links
}

public struct HTMLString: Codable, Equatable, Hashable, @unchecked Sendable {
  public var htmlValue: String = ""
  public var asMarkdown: String = ""
  public var asRawText: String = ""
  public var statusesURLs = [URL]()
  public private(set) var links = [Link]()

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
        links = try container.decode([Link].self, forKey: .links)
      } catch {
        htmlValue = ""
      }
    }

    if !alreadyDecoded {
      // https://daringfireball.net/projects/markdown/syntax
      // Pre-escape \ ` _ * ~ and [ as these are the only
      // characters the markdown parser uses when it renders
      // to attributed text. Note that ~ for strikethrough is
      // not documented in the syntax docs but is used by
      // AttributedString.
      main_regex = try? NSRegularExpression(pattern: "([\\*\\`\\~\\[\\\\])", options: .caseInsensitive)
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
        asRawText = (try? Entities.unescape(text)) ?? text

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
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(htmlValue, forKey: .htmlValue)
    try container.encode(asMarkdown, forKey: .asMarkdown)
    try container.encode(asRawText, forKey: .asRawText)
    try container.encode(statusesURLs, forKey: .statusesURLs)
    try container.encode(links, forKey: .links)
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
        let start = asMarkdown.endIndex
        // descend into this node now so we can wrap the
        // inner part of the link in the right markup
        for nn in node.getChildNodes() {
          handleNode(node: nn)
        }
        let finish = asMarkdown.endIndex

        var linkRef = href

        // Try creating a URL from the string. If it fails, try URL encoding
        //   the string first.
        var url = URL(string: href)
        if url == nil {
          url = URL(string: href, encodePath: true)
        }
        if let linkUrl = url {
          linkRef = linkUrl.absoluteString
          let displayString = asMarkdown[start ..< finish]
          links.append(Link(linkUrl, displayString: String(displayString)))
        }

        asMarkdown += "]("
        asMarkdown += linkRef
        asMarkdown += ")"

        return
      } else if node.nodeName() == "#text" {
        var txt = node.description
        
        txt = (try? Entities.unescape(txt)) ?? txt
        
        if let underscore_regex, let main_regex {
          //  This is the markdown escaper
          txt = main_regex.stringByReplacingMatches(in: txt, options: [], range: NSRange(location: 0, length: txt.count), withTemplate: "\\\\$1")
          txt = underscore_regex.stringByReplacingMatches(in: txt, options: [], range: NSRange(location: 0, length: txt.count), withTemplate: "\\\\$1")
        }
        // Strip newlines and line separators - they should be being sent as <br>s
        asMarkdown += txt.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\u{2028}", with: "")
      } else if node.nodeName() == "ul" {
        // Unordered (bulleted) list
        // SwiftUI's Text won't display these in an AttributedString, but we can at least improve the appearance
        asMarkdown += "\n\n"
        for nn in node.getChildNodes() {
          asMarkdown += "- "
          handleNode(node: nn)
          asMarkdown += "\n"
        }
        return
      } else if node.nodeName() == "ol" {
        // Ordered (numbered) list
        // Same thing, won't display in a Text, but this is just an attempt to improve the appearance
        asMarkdown += "\n\n"
        var curNumber = 1
        for nn in node.getChildNodes() {
          asMarkdown += "\(curNumber). "
          handleNode(node: nn)
          asMarkdown += "\n"
          curNumber += 1
        }
        return
      }

      for n in node.getChildNodes() {
        handleNode(node: n)
      }
    } catch {}
  }

  public struct Link: Codable, Hashable, Identifiable {
    public var id: Int { hashValue }
    public let url: URL
    public let displayString: String
    public let type: LinkType
    public let title: String

    init(_ url: URL, displayString: String) {
      self.url = url
      self.displayString = displayString

      switch displayString.first {
      case "@":
        type = .mention
        title = displayString
      case "#":
        type = .hashtag
        title = String(displayString.dropFirst())
      default:
        type = .url
        var hostNameUrl = url.host ?? url.absoluteString
        if hostNameUrl.hasPrefix("www.") {
          hostNameUrl = String(hostNameUrl.dropFirst(4))
        }
        title = hostNameUrl
      }
    }

    public enum LinkType: String, Codable {
      case url
      case mention
      case hashtag
    }
  }
}

public extension URL {
  // It's common to use non-ASCII characters in URLs even though they're technically
  //   invalid characters. Every modern browser handles this by silently encoding
  //   the invalid characters on the user's behalf. However, trying to create a URL
  //   object with un-encoded characters will result in nil so we need to encode the
  //   invalid characters before creating the URL object. The unencoded version
  //   should still be shown in the displayed status.
  init?(string: String, encodePath: Bool) {
    var encodedUrlString = ""
    if encodePath,
       string.starts(with: "http://") || string.starts(with: "https://"),
       var startIndex = string.firstIndex(of: "/")
    {
      startIndex = string.index(startIndex, offsetBy: 1)

      // We don't want to encode the host portion of the URL
      if var startIndex = string[startIndex...].firstIndex(of: "/") {
        encodedUrlString = String(string[...startIndex])
        while let endIndex = string[string.index(after: startIndex)...].firstIndex(of: "/") {
          let componentStartIndex = string.index(after: startIndex)
          encodedUrlString = encodedUrlString + (string[componentStartIndex ... endIndex].addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
          startIndex = endIndex
        }

        // The last part of the path may have a query string appended to it
        let componentStartIndex = string.index(after: startIndex)
        if let queryStartIndex = string[componentStartIndex...].firstIndex(of: "?") {
          encodedUrlString = encodedUrlString + (string[componentStartIndex ..< queryStartIndex].addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
          encodedUrlString = encodedUrlString + (string[queryStartIndex...].addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        } else {
          encodedUrlString = encodedUrlString + (string[componentStartIndex...].addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
        }
      }
    }
    if encodedUrlString.isEmpty {
      encodedUrlString = string
    }
    self.init(string: encodedUrlString)
  }
}
