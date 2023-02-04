import Foundation
import SwiftSoup
import SwiftUI

public struct HTMLString: Decodable, Equatable, Hashable {
  public var htmlValue: String = ""
  public var asMarkdown: String = ""
  public var asRawText: String = ""
  public var statusesURLs = [URL]()
  public var asSafeMarkdownAttributedString: AttributedString = AttributedString()
  private var regex: NSRegularExpression?
  
  public init(from decoder: Decoder) {
    do {
      let container = try decoder.singleValueContainer()
      htmlValue = try container.decode(String.self)
    } catch {
      htmlValue = ""
    }
    
    // https://daringfireball.net/projects/markdown/syntax
    // Pre-escape \ ` _ * and [ as these are the only
    // characters the markdown parser used picks up
    // when it renders to attributed text
    regex = try? NSRegularExpression(pattern: "([\\_\\*\\`\\[\\\\])", options: .caseInsensitive)
    
    asMarkdown = ""
    do {
      
      let document: Document = try SwiftSoup.parse(htmlValue)
      handleNode(node: document)
      asRawText = try document.text()
    } catch {
      asRawText = htmlValue
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
  
  private mutating func handleNode(node: SwiftSoup.Node ) {
    
    
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
      }
      else if node.nodeName() == "br" {
        if asMarkdown.count > 0 { // ignore first opening <br>
          
          // some code to try and stop double carriage rerturns where they aren't required
          // not perfect but effective in almost all cases
          if !asMarkdown.hasSuffix("\n") && !asMarkdown.hasSuffix("\u{2028}") {
            if let next = node.nextSibling() {
              if next.nodeName() == "#text" && (next.description.hasPrefix("\n") || next.description.hasPrefix("\u{2028}")) {
                // do nothing
              }
              else {
                asMarkdown += "\n"
              }
            }
          }
        }
      }
      else if node.nodeName() == "a" {
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
      }
      else if node.nodeName() == "#text" {
        
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
      
    }
    catch {
      
    }
    
  }
  
  
}
