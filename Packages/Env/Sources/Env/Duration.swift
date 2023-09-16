import SwiftUI

public enum Duration: Int, CaseIterable {
  case infinite = 0
  case fiveMinutes = 300
  case thirtyMinutes = 1800
  case oneHour = 3600
  case sixHours = 21600
  case twelveHours = 43200
  case oneDay = 86400
  case threeDays = 259_200
  case sevenDays = 604_800
  case custom = -1

  public var description: LocalizedStringKey {
    switch self {
    case .infinite:
      "enum.durations.infinite"
    case .fiveMinutes:
      "enum.durations.fiveMinutes"
    case .thirtyMinutes:
      "enum.durations.thirtyMinutes"
    case .oneHour:
      "enum.durations.oneHour"
    case .sixHours:
      "enum.durations.sixHours"
    case .twelveHours:
      "enum.durations.twelveHours"
    case .oneDay:
      "enum.durations.oneDay"
    case .threeDays:
      "enum.durations.threeDays"
    case .sevenDays:
      "enum.durations.sevenDays"
    case .custom:
      "enum.durations.custom"
    }
  }

  public static func mutingDurations() -> [Duration] {
    allCases.filter { $0 != .custom }
  }

  public static func filterDurations() -> [Duration] {
    [.infinite, .thirtyMinutes, .oneHour, .sixHours, .twelveHours, .oneDay, .sevenDays, .custom]
  }

  public static func pollDurations() -> [Duration] {
    [.fiveMinutes, .thirtyMinutes, .oneHour, .sixHours, .twelveHours, .oneDay, .threeDays, .sevenDays]
  }
}
