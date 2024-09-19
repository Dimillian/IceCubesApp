import DesignSystem
import Env
import Foundation
import Models
import Observation
import SwiftUI

@MainActor
@Observable class TimelineUnreadStatusesObserver {
  var pendingStatusesCount: Int = 0

  var disableUpdate: Bool = false

  var isLoadingNewStatuses: Bool = false

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

struct TimelineUnreadStatusesView: View {
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme

  @State var observer: TimelineUnreadStatusesObserver
  let onButtonTap: (String?) -> Void

  var body: some View {
    if observer.pendingStatusesCount > 0 || observer.isLoadingNewStatuses {
      Button {
        onButtonTap(observer.pendingStatuses.last)
      } label: {
        HStack(spacing: 8) {
          if observer.isLoadingNewStatuses {
            ProgressView()
          }
          if observer.pendingStatusesCount > 0 {
            Text("\(observer.pendingStatusesCount)")
              .contentTransition(.numericText(value: Double(observer.pendingStatusesCount)))
              // Accessibility: this results in a frame with a size of at least 44x44 at regular font size
              .frame(minWidth: 16, minHeight: 16)
              .font(.footnote.monospacedDigit())
              .fontWeight(.bold)
          }
        }
      }
      .accessibilityLabel("accessibility.tabs.timeline.unread-posts.label-\(observer.pendingStatusesCount)")
      .accessibilityHint("accessibility.tabs.timeline.unread-posts.hint")
      #if os(visionOS)
        .buttonStyle(.bordered)
        .tint(Material.ultraThick)
      #else
        .buttonStyle(.bordered)
        .background(Material.ultraThick)
      #endif
        .cornerRadius(8)
      #if !os(visionOS)
        .foregroundStyle(.secondary)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(theme.tintColor, lineWidth: 1)
        )
      #endif
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: preferences.pendingLocation)
    }
  }
}
