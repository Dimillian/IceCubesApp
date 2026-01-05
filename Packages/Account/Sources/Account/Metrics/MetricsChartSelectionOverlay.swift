import Charts
import DesignSystem
import SwiftUI

struct MetricsChartSelectionOverlay: View {
  @Environment(Theme.self) private var theme

  let proxy: ChartProxy
  let selectedData: DailyMetric?
  let isLoading: Bool

  var body: some View {
    GeometryReader { geometry in
      if let selectedData, !isLoading {
        let xPosition = proxy.position(forX: selectedData.dayStart) ?? 0
        let plotArea = proxy.plotFrame.map { geometry[$0] } ?? .zero
        let clampedX = min(max(plotArea.minX + xPosition, plotArea.minX + 48), plotArea.maxX - 48)

        VStack(alignment: .leading, spacing: 4) {
          Text(selectedData.dayStart, format: .dateTime.month(.abbreviated).day())
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(selectedData.count, format: .number)
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.labelColor)
        }
        .padding(8)
        .background(
          theme.secondaryBackgroundColor,
          in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(theme.labelColor.opacity(0.15), lineWidth: 1)
        )
        .position(x: clampedX, y: plotArea.minY + 12)
      }
    }
  }
}
