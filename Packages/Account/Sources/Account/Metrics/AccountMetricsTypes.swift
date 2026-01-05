import DesignSystem
import Foundation
import SwiftUI

enum MetricRange: Int, CaseIterable, Identifiable {
  case days7 = 7
  case days30 = 30
  case days90 = 90

  var id: Int { rawValue }

  var title: String {
    switch self {
    case .days7: "7d"
    case .days30: "30d"
    case .days90: "90d"
    }
  }

  var axisStride: Int {
    switch self {
    case .days7: 1
    case .days30: 3
    case .days90: 7
    }
  }
}

enum MetricType: String, CaseIterable, Identifiable {
  case follow
  case favourite
  case reblog
  case mention

  var id: String { rawValue }

  var title: String {
    switch self {
    case .follow: "Follows"
    case .favourite: "Favorites"
    case .reblog: "Boosts"
    case .mention: "Replies"
    }
  }

  var icon: Image {
    switch self {
    case .follow:
      Image(systemName: "person.fill.badge.plus")
    case .favourite:
      Image(systemName: "star.fill")
    case .reblog:
      Image("Rocket.Fill")
    case .mention:
      Image(systemName: "at")
    }
  }

  @MainActor
  var tintColor: Color {
    switch self {
    case .mention:
      Theme.shared.tintColor.opacity(0.80)
    case .reblog:
      Color.teal.opacity(0.80)
    case .follow:
      Color.cyan.opacity(0.80)
    case .favourite:
      Color.yellow.opacity(0.80)
    }
  }
}

enum MetricChartStyle: String, CaseIterable, Identifiable {
  case bars
  case line

  var id: String { rawValue }

  var iconName: String {
    switch self {
    case .bars: "chart.bar.fill"
    case .line: "chart.line.uptrend.xyaxis"
    }
  }
}

struct DailyMetric: Identifiable, Equatable {
  let dayStart: Date
  let count: Int

  var id: Date { dayStart }
}
