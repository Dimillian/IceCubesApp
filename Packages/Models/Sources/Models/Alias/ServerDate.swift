import Foundation

public typealias ServerDate = String

extension ServerDate {
  private static var createdAtDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.calendar = .init(identifier: .iso8601)
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    dateFormatter.timeZone = .init(abbreviation: "UTC")
    return dateFormatter
  }()

  private static var createdAtRelativeFormatter: RelativeDateTimeFormatter = {
    let dateFormatter = RelativeDateTimeFormatter()
    dateFormatter.unitsStyle = .abbreviated
    return dateFormatter
  }()

  private static var createdAtShortDateFormatted: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    return dateFormatter
  }()

  private static let calendar = Calendar(identifier: .gregorian)

  public var asDate: Date {
    Self.createdAtDateFormatter.date(from: self)!
  }

  public var formatted: String {
    if Self.calendar.numberOfDaysBetween(asDate, and: Date()) > 1 {
      return Self.createdAtShortDateFormatted.string(from: asDate)
    } else {
      return Self.createdAtRelativeFormatter.localizedString(for: asDate, relativeTo: Date())
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
