import DesignSystem
import Models
import SwiftUI

struct TimelineGapView: View {
  @Environment(Theme.self) private var theme

  let gap: TimelineGap
  let direction: GapFillDirection
  let onLoadMore: () async -> Void

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Spacer()
        if gap.isLoading {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(theme.labelColor)
        } else {
          Button {
            Task {
              await onLoadMore()
            }
          } label: {
            HStack(spacing: 8) {
              Image(systemName: direction == .fromOlder ? "arrow.up.circle" : "arrow.down.circle")
                .contentTransition(.symbolEffect(.replace))
              Text("Load more")
            }
            .font(.callout)
            .foregroundStyle(theme.tintColor)
          }
          .buttonStyle(.plain)
        }

        Spacer()
      }
      .padding(.vertical, 24)
    }
  }
}
