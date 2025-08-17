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

  public var asAttributedString: AttributedString = .init()
  
  // Deprecated: Use asAttributedString instead
  // Kept for backward compatibility
  public var asSafeMarkdownAttributedString: AttributedString {
    asAttributedString
  }

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
      do {
        let document: Document = try SwiftSoup.parse(htmlValue)

        // Extract raw text
        document.outputSettings(OutputSettings().prettyPrint(pretty: false))
        try document.select("br").after("\n")
        try document.select("p").after("\n\n")
        let html = try document.html()
        var text =
          try SwiftSoup.clean(
            html, "", Whitelist.none(), OutputSettings().prettyPrint(pretty: false)) ?? ""
        // Remove the two last line break added after the last paragraph.
        if text.hasSuffix("\n\n") {
          _ = text.removeLast()
          _ = text.removeLast()
        }
        asRawText = (try? Entities.unescape(text)) ?? text

        // Convert HTML directly to AttributedString
        asAttributedString = try convertToAttributedString(document: document)

        // Generate simplified markdown for backward compatibility
        // This is only used for fallback/caching purposes
        asMarkdown = generateSimpleMarkdown(from: document)

      } catch {
        asRawText = htmlValue
        asAttributedString = AttributedString(htmlValue)
        asMarkdown = htmlValue
      }
    } else {
      // Already decoded from cache - convert HTML again for consistency
      do {
        let document = try SwiftSoup.parse(htmlValue)
        asAttributedString = try convertToAttributedString(document: document)
      } catch {
        // Fallback to markdown parsing if HTML parsing fails
        do {
          let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnlyPreservingWhitespace)
          asAttributedString = try AttributedString(markdown: asMarkdown, options: options)
        } catch {
          asAttributedString = AttributedString(stringLiteral: htmlValue)
        }
      }
    }
  }

  public init(stringValue: String, parseMarkdown: Bool = false) {
    htmlValue = stringValue
    asMarkdown = stringValue
    asRawText = stringValue
    statusesURLs = []

    if parseMarkdown {
      do {
        let options = AttributedString.MarkdownParsingOptions(
          allowsExtendedAttributes: true,
          interpretedSyntax: .inlineOnlyPreservingWhitespace)
        asAttributedString = try AttributedString(
          markdown: asMarkdown, options: options)
      } catch {
        asAttributedString = AttributedString(stringLiteral: htmlValue)
      }
    } else {
      asAttributedString = AttributedString(stringLiteral: htmlValue)
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

  // New direct HTML to AttributedString conversion
  private mutating func convertToAttributedString(document: Document) throws -> AttributedString {
    var result = AttributedString()
    processNode(document, into: &result)
    return result
  }

  private mutating func processNode(
    _ node: SwiftSoup.Node,
    into attributedString: inout AttributedString,
    attributes: AttributeContainer = AttributeContainer()
  ) {
    // Check for invisible or special classes
    if let className = try? node.attr("class") {
      if className == "invisible" {
        return
      }
      if className == "ellipsis" {
        for child in node.getChildNodes() {
          processNode(child, into: &attributedString, attributes: attributes)
        }
        var ellipsis = AttributedString("…")
        ellipsis.mergeAttributes(attributes)
        attributedString += ellipsis
        return
      }
    }

    var currentAttributes = attributes

    switch node.nodeName() {
    case "#text":
      var text = node.description
      text = (try? Entities.unescape(text)) ?? text
      // Strip newlines - they should be sent as <br>s
      text = text.replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\u{2028}", with: "")

      var textString = AttributedString(text)
      textString.mergeAttributes(currentAttributes)
      attributedString += textString

    case "p":
      if !attributedString.characters.isEmpty {
        attributedString += AttributedString("\n\n")
      }
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "br":
      attributedString += AttributedString("\n")

    case "strong", "b":
      currentAttributes.font = .body.bold()
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "em", "i":
      currentAttributes.font = .body.italic()
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "del", "s", "strike":
      currentAttributes.strikethroughStyle = .single
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "u":
      currentAttributes.underlineStyle = .single
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "code":
      currentAttributes.font = .system(.body, design: .monospaced)
      currentAttributes.backgroundColor = Color.gray.opacity(0.15)
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "pre":
      currentAttributes.font = .system(.body, design: .monospaced)
      currentAttributes.backgroundColor = Color.gray.opacity(0.15)
      if !attributedString.characters.isEmpty {
        attributedString += AttributedString("\n")
      }
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }
      attributedString += AttributedString("\n")

    case "blockquote":
      // Add quote styling with visual indicator
      currentAttributes.foregroundColor = Color.secondary

      if !attributedString.characters.isEmpty {
        attributedString += AttributedString("\n")
      }

      // Add quote indicator
      var quotePrefix = AttributedString("▐ ")
      quotePrefix.foregroundColor = Color.accentColor
      attributedString += quotePrefix

      // Process blockquote content
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

      attributedString += AttributedString("\n")

    case "a":
      if let href = try? node.attr("href"),
        let url = URL(string: href) ?? URL(string: href, encodePath: true)
      {

        // Track status URLs
        if Int(url.lastPathComponent) != nil {
          statusesURLs.append(url)
        } else if url.host() == "www.threads.net" || url.host() == "threads.net",
          url.pathComponents.count == 4,
          url.pathComponents[2] == "post"
        {
          statusesURLs.append(url)
        }

        currentAttributes.link = url
        currentAttributes.foregroundColor = Color.accentColor

        let startIndex = attributedString.endIndex
        for child in node.getChildNodes() {
          processNode(child, into: &attributedString, attributes: currentAttributes)
        }
        let endIndex = attributedString.endIndex

        let displayString = String(attributedString[startIndex..<endIndex].characters)
        links.append(Link(url, displayString: displayString))
      } else {
        for child in node.getChildNodes() {
          processNode(child, into: &attributedString, attributes: attributes)
        }
      }

    case "h1", "h2", "h3", "h4", "h5", "h6":
      let level = Int(String(node.nodeName().dropFirst())) ?? 1
      let sizes: [Font] = [.largeTitle, .title, .title2, .title3, .headline, .subheadline]
      currentAttributes.font = sizes[min(level - 1, sizes.count - 1)].bold()

      if !attributedString.characters.isEmpty {
        attributedString += AttributedString("\n\n")
      }
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }
      attributedString += AttributedString("\n")

    case "ul", "ol":
      if !attributedString.characters.isEmpty {
        attributedString += AttributedString("\n")
      }

      var listCounter = 1
      for child in node.getChildNodes() {
        if child.nodeName() == "li" {
          processListItem(
            child,
            into: &attributedString,
            ordered: node.nodeName() == "ol",
            index: listCounter,
            attributes: currentAttributes
          )
          listCounter += 1
        } else {
          processNode(child, into: &attributedString, attributes: currentAttributes)
        }
      }

    case "sup":
      currentAttributes.baselineOffset = 4
      currentAttributes.font = .caption
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "sub":
      currentAttributes.baselineOffset = -4
      currentAttributes.font = .caption
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "mark":
      currentAttributes.backgroundColor = Color.yellow.opacity(0.3)
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "abbr":
      if let title = try? node.attr("title"), !title.isEmpty {
        currentAttributes.underlineStyle = .single
        // Note: underlineColor can be set but requires UIKit bridge
      }
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    case "span":
      // Process span with possible inline styles
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }

    default:
      // Process children for unknown tags
      for child in node.getChildNodes() {
        processNode(child, into: &attributedString, attributes: currentAttributes)
      }
    }
  }

  private mutating func processListItem(
    _ node: SwiftSoup.Node,
    into attributedString: inout AttributedString,
    ordered: Bool,
    index: Int,
    attributes: AttributeContainer
  ) {
    let bullet = ordered ? "\(index). " : "• "
    var bulletString = AttributedString("   \(bullet)")
    bulletString.mergeAttributes(attributes)
    attributedString += bulletString

    for child in node.getChildNodes() {
      processNode(child, into: &attributedString, attributes: attributes)
    }
    attributedString += AttributedString("\n")
  }

  // Simplified markdown generation for backward compatibility
  private mutating func generateSimpleMarkdown(from document: Document) -> String {
    var markdown = ""
    generateMarkdownFromNode(document, into: &markdown)
    if markdown.hasPrefix("\n") {
      markdown.removeFirst()
    }
    return markdown
  }

  private mutating func generateMarkdownFromNode(
    _ node: SwiftSoup.Node,
    into markdown: inout String
  ) {
    // Simplified version for caching/fallback only
    switch node.nodeName() {
    case "#text":
      var text = node.description
      text = (try? Entities.unescape(text)) ?? text
      markdown += text.replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\u{2028}", with: "")

    case "p":
      if !markdown.isEmpty {
        markdown += "\n\n"
      }
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }

    case "br":
      markdown += "\n"

    case "strong", "b":
      markdown += "**"
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }
      markdown += "**"

    case "em", "i":
      markdown += "_"
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }
      markdown += "_"

    case "del", "s", "strike":
      markdown += "~~"
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }
      markdown += "~~"

    case "code":
      markdown += "`"
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }
      markdown += "`"

    case "blockquote":
      markdown += "\n> "
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }
      markdown += "\n"

    case "a":
      let href = (try? node.attr("href")) ?? ""
      markdown += "["
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }
      markdown += "](\(href))"

    default:
      for child in node.getChildNodes() {
        generateMarkdownFromNode(child, into: &markdown)
      }
    }
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

extension URL {
  // It's common to use non-ASCII characters in URLs even though they're technically
  //   invalid characters. Every modern browser handles this by silently encoding
  //   the invalid characters on the user's behalf. However, trying to create a URL
  //   object with un-encoded characters will result in nil so we need to encode the
  //   invalid characters before creating the URL object. The unencoded version
  //   should still be shown in the displayed status.
  public init?(string: String, encodePath: Bool) {
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
          encodedUrlString =
            encodedUrlString
            + (string[componentStartIndex...endIndex].addingPercentEncoding(
              withAllowedCharacters: .urlPathAllowed) ?? "")
          startIndex = endIndex
        }

        // The last part of the path may have a query string appended to it
        let componentStartIndex = string.index(after: startIndex)
        if let queryStartIndex = string[componentStartIndex...].firstIndex(of: "?") {
          encodedUrlString =
            encodedUrlString
            + (string[componentStartIndex..<queryStartIndex].addingPercentEncoding(
              withAllowedCharacters: .urlPathAllowed) ?? "")
          encodedUrlString =
            encodedUrlString
            + (string[queryStartIndex...].addingPercentEncoding(
              withAllowedCharacters: .urlQueryAllowed) ?? "")
        } else {
          encodedUrlString =
            encodedUrlString
            + (string[componentStartIndex...].addingPercentEncoding(
              withAllowedCharacters: .urlPathAllowed) ?? "")
        }
      }
    }
    if encodedUrlString.isEmpty {
      encodedUrlString = string
    }
    self.init(string: encodedUrlString)
  }
}
