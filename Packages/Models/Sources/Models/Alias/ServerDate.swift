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
    dateFormatter.unitsStyle = .short
    return dateFormatter
  }()

  private static var createdAtShortDateFormatted: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none
    return dateFormatter
  }()

  private static let calendar = Calendar(identifier: .gregorian)

  public var asDate: Date {
    Self.createdAtDateFormatter.date(from: self)!
  }

  public var relativeFormatted: String {
    return Self.createdAtRelativeFormatter.localizedString(for: asDate, relativeTo: Date())
  }

  public var shortDateFormatted: String {
    return Self.createdAtShortDateFormatted.string(from: asDate)
  }
}
