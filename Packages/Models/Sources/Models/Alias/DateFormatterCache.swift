import Foundation

class DateFormatterCache: @unchecked Sendable {
  static let shared = DateFormatterCache()

  let createdAtRelativeFormatter: RelativeDateTimeFormatter
  let createdAtShortRelativeFormatter: DateComponentsFormatter
  let createdAtShortDateFormatted: DateFormatter
  let createdAtDateFormatter: DateFormatter

  init() {
    let createdAtRelativeFormatter = RelativeDateTimeFormatter()
    createdAtRelativeFormatter.unitsStyle = .short
    createdAtRelativeFormatter.formattingContext = .listItem
    createdAtRelativeFormatter.dateTimeStyle = .numeric
    self.createdAtRelativeFormatter = createdAtRelativeFormatter

    let createdAtShortRelativeFormatter = DateComponentsFormatter()
    createdAtShortRelativeFormatter.maximumUnitCount = 1
    createdAtShortRelativeFormatter.unitsStyle = .abbreviated
    createdAtShortRelativeFormatter.zeroFormattingBehavior = .dropAll
    createdAtShortRelativeFormatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
    self.createdAtShortRelativeFormatter = createdAtShortRelativeFormatter

    let createdAtShortDateFormatted = DateFormatter()
    createdAtShortDateFormatted.dateStyle = .short
    createdAtShortDateFormatted.timeStyle = .none
    self.createdAtShortDateFormatted = createdAtShortDateFormatted

    let createdAtDateFormatter = DateFormatter()
    createdAtDateFormatter.calendar = .init(identifier: .iso8601)
    createdAtDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    createdAtDateFormatter.timeZone = .init(abbreviation: "UTC")
    self.createdAtDateFormatter = createdAtDateFormatter
  }
}
