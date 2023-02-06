import SwiftUI

enum MutingDurations: Int, CaseIterable {
  case infinite = 0
  case fiveMinutes = 300
  case thirtyMinutes = 1_800
  case oneHour = 3_600
  case sixHours = 21_600
  case oneDay = 86_400
  case threeDays = 259_200
  case sevenDays = 604_800
  
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
    case .oneDay:
      return "enum.durations.oneDay"
    case .threeDays:
      return "enum.durations.threeDays"
    case .sevenDays:
      return "enum.durations.sevenDays"
    }
  }
}
