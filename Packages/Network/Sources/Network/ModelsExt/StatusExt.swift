import HTML2Markdown
import Foundation

extension Status {
  public var contentAsMarkdown: String {
    do {
      let dom = try HTMLParser().parse(html: content)
      return dom.toMarkdown()
    } catch {
      return content
    }
  }
  
  public var createdAtDate: Date {
    let dateFormatter = DateFormatter()
    dateFormatter.calendar = .init(identifier: .iso8601)
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    dateFormatter.timeZone = .init(abbreviation: "UTC")
    return dateFormatter.date(from: createdAt)!
  }
  
  public var createdAtFormatted: String {
    let dateFormatter = RelativeDateTimeFormatter()
    dateFormatter.unitsStyle = .abbreviated
    return dateFormatter.localizedString(for: createdAtDate, relativeTo: Date())
  }
}
