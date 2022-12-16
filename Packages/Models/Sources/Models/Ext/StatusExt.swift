import HTML2Markdown
import Foundation

extension AnyStatus {
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
  
  private static var createdAtShortDateFormatted: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
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
    let calendar = Calendar(identifier: .gregorian)
    if calendar.numberOfDaysBetween(createdAtDate, and: Date()) > 1 {
      return Self.createdAtShortDateFormatted.string(from: createdAtDate)
    } else {
      return Self.createdAtRelativeFormatter.localizedString(for: createdAtDate, relativeTo: Date())
    }
  }
}

extension Calendar {
  func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
    let fromDate = startOfDay(for: from)
    let toDate = startOfDay(for: to)
    let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
    
    return numberOfDays.day!
  }
}
