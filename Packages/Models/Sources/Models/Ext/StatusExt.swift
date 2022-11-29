import HTML2Markdown
import Foundation

extension Status {
  private static var createdAtDateFormatter: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.calendar = .init(identifier: .iso8601)
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    dateFormatter.timeZone = .init(abbreviation: "UTC")
    return dateFormatter
  }
  
  private static var createdAtRelativeFormatter: RelativeDateTimeFormatter {
    let dateFormatter = RelativeDateTimeFormatter()
    dateFormatter.unitsStyle = .abbreviated
    return dateFormatter
  }
  
  public var contentAsMarkdown: String {
    do {
      let dom = try HTMLParser().parse(html: content)
      return dom.toMarkdown()
    } catch {
      return content
    }
  }
  
  public var createdAtDate: Date {
    Self.createdAtDateFormatter.date(from: createdAt)!
  }
  
  public var createdAtFormatted: String {
    Self.createdAtRelativeFormatter.localizedString(for: createdAtDate, relativeTo: Date())
  }
}
