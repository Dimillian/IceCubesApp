import Foundation

private enum CodingKeys: CodingKey {
  case asDate
}

public struct ServerDate: Codable, Hashable, Equatable, Sendable {
  public let asDate: Date

  public var relativeFormatted: String {
    Self.createdAtRelativeFormatter.localizedString(for: asDate, relativeTo: Date())
  }

  public var shortDateFormatted: String {
    Self.createdAtShortDateFormatted.string(from: asDate)
  }

  private static let calendar = Calendar(identifier: .gregorian)

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

  public init() {
    asDate = Date() - 100
  }

  public init(from decoder: Decoder) throws {
    do {
      // Decode from server
      let container = try decoder.singleValueContainer()
      let stringDate = try container.decode(String.self)
      asDate = Self.createdAtDateFormatter.date(from: stringDate) ?? Date()
    } catch {
      // Decode from cache
      let container = try decoder.container(keyedBy: CodingKeys.self)
      asDate = try container.decode(Date.self, forKey: .asDate)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(asDate, forKey: .asDate)
  }
}
