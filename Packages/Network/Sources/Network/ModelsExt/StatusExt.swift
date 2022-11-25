import SwiftSoup
import HTML2Markdown

extension Status {
  public var contentAsMarkdown: String {
    do {
      let dom = try HTMLParser().parse(html: content)
      return dom.toMarkdown()
    } catch {
      return content
    }
  }
}
