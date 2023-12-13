import SwiftUI
import Charts
import Models

public struct TagChartView: View {
  let tag: Tag
  
  public init(tag: Tag) {
    self.tag = tag
  }
  
  public var body: some View {
    Chart(tag.sortedHistory) { data in
      AreaMark(x: .value("day", tag.sortedHistory.firstIndex(where: { $0.id == data.id }) ?? 0),
               y: .value("uses", Int(data.uses) ?? 0))
      .interpolationMethod(.catmullRom)
    }
    .chartLegend(.hidden)
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .frame(width: 70, height: 40)
    .clipShape(RoundedRectangle(cornerRadius: 4))
  }
}
