import Foundation
import SwiftSoup
import SwiftUI

private enum CodingKeys: CodingKey {
  case htmlValue, asMarkdown, asRawText, statusesURLs, links, hadTrailingTags
}

public struct HTMLString: Codable, Equatable, Hashable, @unchecked Sendable {
  public var htmlValue: String = ""
  public var asMarkdown: String = ""
  public var asRawText: String = ""
  public var statusesURLs = [URL]()
  public private(set) var links = [Link]()
  public private(set) var hadTrailingTags = false

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
        hadTrailingTags = (try? container.decode(Bool.self, forKey: .hadTrailingTags)) ?? false
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
      main_regex = try? NSRegularExpression(
        pattern: "([\\*\\`\\~\\[\\\\])", options: .caseInsensitive)
      // don't escape underscores that are between colons, they are most likely custom emoji
      underscore_regex = try? NSRegularExpression(
        pattern: "(?!\\B:[^:]*)(_)(?![^:]*:\\B)", options: .caseInsensitive)

      asMarkdown = ""
      do {
        let document: SwiftSoup.Document = try SwiftSoup.parse(htmlValue)
        var listCounters: [Int] = []
        handleNode(node: document, listCounters: &listCounters)

        document.outputSettings(OutputSettings().prettyPrint(pretty: false))
        try document.select("p.quote-inline").remove()
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

        if asMarkdown.hasPrefix("\n") {
          _ = asMarkdown.removeFirst()
        }

        // Remove trailing hashtags
        removeTrailingTags(doc: document)

        // Regenerate attributed string after extracting tags
        do {
          let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnlyPreservingWhitespace)
          asSafeMarkdownAttributedString = try AttributedString(
            markdown: asMarkdown, options: options)
        } catch {
          asSafeMarkdownAttributedString = AttributedString(stringLiteral: asMarkdown)
        }

      } catch {
        asRawText = htmlValue
      }
    } else {
      do {
        let options = AttributedString.MarkdownParsingOptions(
          allowsExtendedAttributes: true,
          interpretedSyntax: .inlineOnlyPreservingWhitespace)
        asSafeMarkdownAttributedString = try AttributedString(
          markdown: asMarkdown, options: options)
      } catch {
        asSafeMarkdownAttributedString = AttributedString(stringLiteral: htmlValue)
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
        asSafeMarkdownAttributedString = try AttributedString(
          markdown: asMarkdown, options: options)
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
    try container.encode(hadTrailingTags, forKey: .hadTrailingTags)
  }

  private mutating func removeTrailingTags(doc: SwiftSoup.Document) {
    // Fast bail-outs
    if !asMarkdown.contains("#") { return }

    // Split markdown by double newlines to get paragraphs (same as building logic)
    let paragraphs = asMarkdown.split(separator: "\n\n", omittingEmptySubsequences: false).map(
      String.init)
    guard
      let lastIndex = paragraphs.lastIndex(where: {
        !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      })
    else {
      return
    }

    // Inspect original HTML last paragraph to find trailing hashtags: either the whole paragraph
    // or only its last line, when the hashtags follow a line break instead of a new paragraph.
    // Not a quote-inline. This avoids regex backtracking on large inputs.
    let trailingTags: TrailingTags = {
      do {
        let paras = try doc.select("p:not(.quote-inline)")
        guard let lastP = paras.array().last else { return .none }
        var isEveryLineTagsOnly = true
        var isLastLineTagsOnly = true
        var lastLineHasHashtag = false
        for child in lastP.getChildNodes() {
          let name = child.nodeName()
          var isTagOrWhitespace = false
          if name == "br" {
            // A new line starts, only what follows can be trailing hashtags
            isLastLineTagsOnly = true
            lastLineHasHashtag = false
            continue
          } else if name == "#text" {
            // Allow whitespace-only text
            let txt = child.description.trimmingCharacters(in: .whitespacesAndNewlines)
            isTagOrWhitespace = txt.isEmpty
          } else if name == "a" {
            // Accept only anchors that look like hashtag links
            let cls = (try? child.attr("class")) ?? ""
            isTagOrWhitespace = cls.contains("hashtag")
            if isTagOrWhitespace { lastLineHasHashtag = true }
          }
          // Any other element means mixed content
          if !isTagOrWhitespace {
            isEveryLineTagsOnly = false
            isLastLineTagsOnly = false
          }
        }
        guard isLastLineTagsOnly, lastLineHasHashtag else { return .none }
        return isEveryLineTagsOnly ? .paragraph : .lastLine
      } catch {
        return .none
      }
    }()

    switch trailingTags {
    case .none:
      return
    case .paragraph:
      // Remove the last non-empty paragraph from both markdown and raw text
      hadTrailingTags = true
      let updatedMarkdownParagraphs = Array(paragraphs.prefix(lastIndex))
      asMarkdown = updatedMarkdownParagraphs.joined(separator: "\n\n")

      let rawParagraphs = asRawText.split(separator: "\n\n", omittingEmptySubsequences: false).map(
        String.init)
      if lastIndex < rawParagraphs.count {
        let updatedRawParagraphs = Array(rawParagraphs.prefix(lastIndex))
        asRawText = updatedRawParagraphs.joined(separator: "\n\n")
      }
    case .lastLine:
      // Remove only the last line, the text above it stays
      guard let markdown = Self.removingLastLine(from: asMarkdown),
        let rawText = Self.removingLastLine(from: asRawText)
      else { return }
      hadTrailingTags = true
      asMarkdown = markdown
      asRawText = rawText
    }
  }

  private enum TrailingTags {
    case none, paragraph, lastLine
  }

  private static func removingLastLine(from text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let lineBreak = trimmed.lastIndex(of: "\n") else { return nil }
    return String(trimmed[..<lineBreak]).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private mutating func handleNode(
    node: SwiftSoup.Node,
    indent: Int? = 0,
    skipParagraph: Bool = false,
    listCounters: inout [Int]
  ) {
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
            handleNode(node: nn, indent: indent, listCounters: &listCounters)
          }
          asMarkdown += "…"
          return
        }
      }

      if node.nodeName() == "p" {
        if let className = try? node.attr("class"), className == "quote-inline" {
          return
        }
        if asMarkdown.count > 0 && !skipParagraph {
          asMarkdown += "\n\n"
        }
      } else if node.nodeName() == "br" {
        if asMarkdown.count > 0 {  // ignore first opening <br>
          asMarkdown += "\n"
        }
        if (indent ?? 0) > 0 {
          asMarkdown += "\n"
        }
      } else if node.nodeName() == "a" {
        let href = try node.attr("href")
        if href != "" {
          if let url = URL(string: href) {
            if Int(url.lastPathComponent) != nil {
              statusesURLs.append(url)
            } else if url.host() == "www.threads.net" || url.host() == "threads.net",
              url.pathComponents.count == 4,
              url.pathComponents[2] == "post"
            {
              statusesURLs.append(url)
            }
          }
        }
        asMarkdown += "["
        let start = asMarkdown.endIndex
        // descend into this node now so we can wrap the
        // inner part of the link in the right markup
        for nn in node.getChildNodes() {
          handleNode(node: nn, listCounters: &listCounters)
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
          let displayString = asMarkdown[start..<finish]
          links.append(Link(linkUrl, displayString: String(displayString)))
        }

        asMarkdown += "]("
        asMarkdown += linkRef
        asMarkdown += ")"

        return
      } else if node.nodeName() == "#text" {
        var txt = node.description

        txt = (try? Entities.unescape(txt)) ?? txt
        let isLineStart = asMarkdown.isEmpty || asMarkdown.hasSuffix("\n")

        if let underscore_regex, let main_regex {
          //  This is the markdown escaper
          txt = main_regex.stringByReplacingMatches(
            in: txt, options: [], range: NSRange(location: 0, length: txt.count),
            withTemplate: "\\\\$1")
          txt = underscore_regex.stringByReplacingMatches(
            in: txt, options: [], range: NSRange(location: 0, length: txt.count),
            withTemplate: "\\\\$1")
        }
        if isLineStart,
          txt.hasPrefix("- ") || txt.hasPrefix("* ") || txt.hasPrefix("+ ")
        {
          txt = "\\" + txt
        }
        // Strip newlines and line separators - they should be being sent as <br>s
        asMarkdown += txt.replacingOccurrences(of: "\n", with: "").replacingOccurrences(
          of: "\u{2028}", with: "")
      } else if node.nodeName() == "blockquote" {
        asMarkdown += "\n\n`"
        for nn in node.getChildNodes() {
          handleNode(node: nn, indent: indent, listCounters: &listCounters)
        }
        asMarkdown += "`"
        return
      } else if node.nodeName() == "strong" || node.nodeName() == "b" {
        asMarkdown += "**"
        for nn in node.getChildNodes() {
          handleNode(node: nn, indent: indent, listCounters: &listCounters)
        }
        asMarkdown += "**"
        return
      } else if node.nodeName() == "em" || node.nodeName() == "i" {
        asMarkdown += "_"
        for nn in node.getChildNodes() {
          handleNode(node: nn, indent: indent, listCounters: &listCounters)
        }
        asMarkdown += "_"
        return
      } else if node.nodeName() == "ul" || node.nodeName() == "ol" {

        if skipParagraph {
          asMarkdown += "\n"
        } else {
          asMarkdown += "\n\n"
        }

        var listCounters = listCounters

        if node.nodeName() == "ol" {
          listCounters.append(1)  // Start numbering for a new ordered list
        }

        for nn in node.getChildNodes() {
          handleNode(node: nn, indent: (indent ?? 0) + 1, listCounters: &listCounters)
        }

        if node.nodeName() == "ol" {
          listCounters.removeLast()
        }

        return
      } else if node.nodeName() == "li" {
        asMarkdown += "   "
        if let indent, indent > 1 {
          for _ in 0..<indent {
            asMarkdown += "   "
          }
          asMarkdown += "- "
        }

        if listCounters.isEmpty {
          asMarkdown += "• "
        } else {
          let currentIndex = listCounters.count - 1
          asMarkdown += "\(listCounters[currentIndex]). "
          listCounters[currentIndex] += 1
        }

        for nn in node.getChildNodes() {
          handleNode(node: nn, indent: indent, skipParagraph: true, listCounters: &listCounters)
        }
        asMarkdown += "\n"
        return
      }

      for n in node.getChildNodes() {
        handleNode(node: n, indent: indent, listCounters: &listCounters)
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
