import Charts
import DesignSystem
import SwiftUI

struct MetricsChartCard: View {
  @Environment(\.calendar) private var calendar
  @Environment(Theme.self) private var theme

  let dailyData: [DailyMetric]
  let animatedDailyData: [DailyMetric]
  let isLoading: Bool
  let selectedMetric: MetricType
  let range: MetricRange
  @Binding var chartStyle: MetricChartStyle
  let maxValue: Int
  let onSelectMetric: (MetricType) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      HStack {
        Menu {
          ForEach(MetricType.allCases) { metric in
            Button {
              onSelectMetric(metric)
            } label: {
              Label {
                Text(metric.title)
              } icon: {
                metric.icon
              }
            }
          }
        } label: {
          Label {
            Text(selectedMetric.title)
              .font(.headline)
          } icon: {
            Image(systemName: "chevron.down")
              .font(.caption)
          }
          .labelStyle(.titleAndIcon)
          .foregroundStyle(theme.labelColor)
          .accessibilityLabel(selectedMetric.title)
        }
        .tint(theme.labelColor)
        Spacer()
        Picker("Chart style", selection: $chartStyle) {
          ForEach(MetricChartStyle.allCases) { style in
            Image(systemName: style.iconName)
              .tag(style)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 96)
      }

      Chart(chartStyle == .bars ? animatedDailyData : dailyData) { data in
        switch chartStyle {
        case .bars:
          let halfWidth = barWidthSeconds / 2
          RectangleMark(
            xStart: .value("DayStart", data.dayStart.addingTimeInterval(-halfWidth)),
            xEnd: .value("DayEnd", data.dayStart.addingTimeInterval(halfWidth)),
            yStart: .value("Base", 0),
            yEnd: .value("Count", data.count)
          )
          .foregroundStyle(selectedMetric.tintColor)
        case .line:
          LineMark(
            x: .value("Day", data.dayStart),
            y: .value("Count", data.count)
          )
          .foregroundStyle(selectedMetric.tintColor)
          .symbol(.circle)
        }
      }
      .chartXScale(range: .plotDimension(startPadding: 12, endPadding: 12))
      .chartYScale(domain: 0...max(maxValue, 1))
      .chartXAxis {
        AxisMarks(values: axisDates) { value in
          AxisValueLabel(
            format: .dateTime.month(.abbreviated).day(),
            centered: true
          )
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading)
      }
      .frame(height: 220)
      .redacted(reason: isLoading ? .placeholder : [])
      .animation(.easeInOut(duration: 0.25), value: animatedDailyData)
      .animation(.easeInOut(duration: 0.25), value: chartStyle)
    }
    .padding(12)
    .background(theme.secondaryBackgroundColor, in: RoundedRectangle(cornerRadius: 16))
  }

  private var axisDates: [Date] {
    guard let first = dailyData.first?.dayStart,
      let last = dailyData.last?.dayStart
    else {
      return []
    }

    switch range {
    case .days7:
      let mid = calendar.date(byAdding: .day, value: 3, to: first) ?? first
      return [first, mid, last]
    case .days30, .days90:
      var dates: [Date] = []
      var current = first
      while current <= last {
        dates.append(current)
        let step = range == .days30 ? 7 : 14
        current = calendar.date(byAdding: .day, value: step, to: current) ?? last
        if current == last {
          break
        }
      }
      if dates.last != last {
        dates.append(last)
      }
      return dates
    }
  }

  private var barWidthSeconds: TimeInterval {
    let day: TimeInterval = 60 * 60 * 24
    switch range {
    case .days7:
      return day * 0.9
    case .days30:
      return day * 0.6
    case .days90:
      return day * 0.25
    }
  }
}

struct MetricSummaryCard: View {
  @Environment(Theme.self) private var theme
  let title: String
  let value: Int
  let delta: Double?
  let isLoading: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(value, format: .number)
          .font(.title2.bold())
        if let delta {
          Text(delta, format: .percent.precision(.fractionLength(0)))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(delta >= 0 ? Color.green : Color.red)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(theme.secondaryBackgroundColor, in: RoundedRectangle(cornerRadius: 14))
    .redacted(reason: isLoading ? .placeholder : [])
  }
}
