import Charts
import Models
import SwiftUI

public struct TagChartView: View {
  @State private var sortedHistory: [History] = []

  public init(tag: Tag) {
    _sortedHistory = .init(
      initialValue: tag.history.sorted {
        Int($0.day) ?? 0 < Int($1.day) ?? 0
      })
  }

  public var body: some View {
    Chart(sortedHistory) { data in
      AreaMark(
        x: .value("day", sortedHistory.firstIndex(where: { $0.id == data.id }) ?? 0),
        y: .value("uses", Int(data.uses) ?? 0)
      )
      .interpolationMethod(.catmullRom)
    }
    .chartLegend(.hidden)
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .frame(width: 70, height: 40)
    .clipShape(RoundedRectangle(cornerRadius: 4))
  }
}
