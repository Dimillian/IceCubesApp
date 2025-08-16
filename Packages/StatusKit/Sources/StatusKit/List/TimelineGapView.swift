import DesignSystem
import Models
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct GapMidYPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

struct TimelineGapView: View {
  @Environment(Theme.self) private var theme

  let gap: TimelineGap
  let onLoadMore: () async -> Void

  @State private var isInBottomHalf: Bool = false

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
              Image(systemName: arrowSystemName)
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
      .background(
        GeometryReader { proxy in
          Color.clear
            .preference(key: GapMidYPreferenceKey.self, value: proxy.frame(in: .global).midY)
        }
      )
      .onPreferenceChange(GapMidYPreferenceKey.self) { midY in
        #if canImport(UIKit)
        let screenHeight = UIScreen.main.bounds.height
        #elseif canImport(AppKit)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        #else
        let screenHeight: CGFloat = 0
        #endif
        if screenHeight > 0 {
          isInBottomHalf = midY > screenHeight / 2
        } else {
          isInBottomHalf = false
        }
      }
    }
  }

  private var arrowSystemName: String {
    // Only bidirectional for bridge gaps (when sinceId exists). Older-only gaps stay downward.
    if gap.sinceId.isEmpty {
      return "arrow.down.circle"
    }
    return isInBottomHalf ? "arrow.up.circle" : "arrow.down.circle"
  }
}
