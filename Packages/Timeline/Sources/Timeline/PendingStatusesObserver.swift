import Env
import Foundation
import Models
import Observation
import SwiftUI
import DesignSystem

@MainActor
@Observable class PendingStatusesObserver {
  var pendingStatusesCount: Int = 0

  var disableUpdate: Bool = false
  var scrollToIndex: ((Int) -> Void)?

  var pendingStatuses: [String] = [] {
    didSet {
      withAnimation(.default) {
        pendingStatusesCount = pendingStatuses.count
      }
    }
  }

  func removeStatus(status: Status) {
    if !disableUpdate, let index = pendingStatuses.firstIndex(of: status.id) {
      pendingStatuses.removeSubrange(index ... (pendingStatuses.count - 1))
      HapticManager.shared.fireHaptic(.timeline)
    }
  }

  init() {}
}

struct PendingStatusesObserverView: View {
  @State var observer: PendingStatusesObserver
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme
  
  var body: some View {
    if observer.pendingStatusesCount > 0 {
      Button {
        observer.scrollToIndex?(observer.pendingStatusesCount)
      } label: {
        Text("\(observer.pendingStatusesCount)")
          .contentTransition(.numericText(countsDown: true))
          // Accessibility: this results in a frame with a size of at least 44x44 at regular font size
          .frame(minWidth: 16, minHeight: 16)
          .font(.footnote.monospacedDigit())
      }
      .accessibilityLabel("accessibility.tabs.timeline.unread-posts.label-\(observer.pendingStatusesCount)")
      .accessibilityHint("accessibility.tabs.timeline.unread-posts.hint")
      #if os(visionOS)
      .buttonStyle(.bordered)
      .tint(Material.thick)
      #else
      .buttonStyle(.bordered)
      .background(.thinMaterial)
      #endif
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(theme.tintColor, lineWidth: 1)
      )
      .padding(8)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: preferences.pendingLocation)
    }
  }
}
