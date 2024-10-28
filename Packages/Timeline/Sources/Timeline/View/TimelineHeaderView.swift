import DesignSystem
import SwiftUI

struct TimelineHeaderView<Content: View>: View {
  @Environment(Theme.self) private var theme

  var content: () -> Content

  var body: some View {
    VStack(alignment: .leading) {
      Spacer()
      content()
      Spacer()
    }
    #if os(visionOS)
      .listRowBackground(
        RoundedRectangle(cornerRadius: 8)
          .foregroundStyle(.background).hoverEffect()
      )
      .listRowHoverEffectDisabled()
    #else
      .listRowBackground(theme.secondaryBackgroundColor)
    #endif
    .listRowSeparator(.hidden)
    .listRowInsets(
      .init(
        top: 8,
        leading: .layoutPadding,
        bottom: 8,
        trailing: .layoutPadding))
  }
}
