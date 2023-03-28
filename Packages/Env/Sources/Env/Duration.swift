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
      return "enum.durations.infinite"
    case .fiveMinutes:
      return "enum.durations.fiveMinutes"
    case .thirtyMinutes:
      return "enum.durations.thirtyMinutes"
    case .oneHour:
      return "enum.durations.oneHour"
    case .sixHours:
      return "enum.durations.sixHours"
    case .twelveHours:
      return "enum.durations.twelveHours"
    case .oneDay:
      return "enum.durations.oneDay"
    case .threeDays:
      return "enum.durations.threeDays"
    case .sevenDays:
      return "enum.durations.sevenDays"
    case .custom:
      return "enum.durations.custom"
    }
  }

  public static func mutingDurations() -> [Duration] {
    return Self.allCases.filter { $0 != .custom }
  }

  public static func filterDurations() -> [Duration] {
    return [.infinite, .thirtyMinutes, .oneHour, .sixHours, .twelveHours, .oneDay, .sevenDays, .custom]
  }

  public static func pollDurations() -> [Duration] {
    return [.fiveMinutes, .thirtyMinutes, .oneHour, .sixHours, .twelveHours, .oneDay, .threeDays, .sevenDays]
  }
}
