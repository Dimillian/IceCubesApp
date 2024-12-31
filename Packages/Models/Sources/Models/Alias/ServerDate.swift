import Foundation

private enum CodingKeys: CodingKey {
  case asDate
}

public struct ServerDate: Codable, Hashable, Equatable, Sendable {
  public let asDate: Date
  private let isOlderThanADay: Bool

  public var relativeFormatted: String {
    let date = asDate
    if isOlderThanADay {
      return DateFormatterCache.shared.createdAtRelativeFormatter.localizedString(
        for: date,
        relativeTo: Date())
    } else {
      return Duration.seconds(-date.timeIntervalSinceNow).formatted(
        .units(
          width: .narrow,
          maximumUnitCount: 1))
    }
  }

  public var shortDateFormatted: String {
    DateFormatterCache.shared.createdAtShortDateFormatted.string(from: asDate)
  }

  private static let calendar = Calendar(identifier: .gregorian)

  public init() {
    asDate = Date() - 100
    isOlderThanADay = false
  }

  public init(from decoder: Decoder) throws {
    do {
      // Decode from server
      let container = try decoder.singleValueContainer()
      let stringDate = try container.decode(String.self)
      asDate = DateFormatterCache.shared.createdAtDateFormatter.date(from: stringDate) ?? Date()
    } catch {
      // Decode from cache
      let container = try decoder.container(keyedBy: CodingKeys.self)
      asDate = try container.decode(Date.self, forKey: .asDate)
    }

    let aDay: TimeInterval = 60 * 60 * 24
    isOlderThanADay = Date().timeIntervalSince(asDate) >= aDay
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(asDate, forKey: .asDate)
  }
}
