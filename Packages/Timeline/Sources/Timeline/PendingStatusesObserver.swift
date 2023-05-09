import Env
import Foundation
import Models
import SwiftUI

@MainActor
class PendingStatusesObserver: ObservableObject {
  @Published private(set) var pendingStatusesCount: Int = 0

  var disableUpdate: Bool = false
  var scrollToIndex: ((Int) -> Void)?

  let userPreferences = UserPreferences.shared

  var pendingStatuses: [Status] = [] {
    didSet {
      refreshCount()
    }
  }

  func refreshCount() {
    pendingStatusesCount = pendingStatuses.filter { !$0.isThread || userPreferences.showReplies }.count
  }

  func removeStatus(status: Status) {
    if !disableUpdate, let index = pendingStatuses.firstIndex(of: status) {
      pendingStatuses.removeSubrange(index ... (pendingStatuses.count - 1))
      HapticManager.shared.fireHaptic(of: .timeline)
    }
  }

  init() {}
}

struct PendingStatusesObserverView: View {
  @ObservedObject var observer: PendingStatusesObserver
  @EnvironmentObject var userPreferences: UserPreferences

  var body: some View {
    Group {
      if observer.pendingStatusesCount > 0 {
        HStack(spacing: 6) {
          Spacer()
          Button {
            observer.scrollToIndex?(observer.pendingStatusesCount)
          } label: {
            Text("\(observer.pendingStatusesCount)")
              // Accessibility: this results in a frame with a size of at least 44x44 at regular font size
              .frame(minWidth: 30, minHeight: 30)
          }
          .accessibilityLabel("accessibility.tabs.timeline.unread-posts.label-\(observer.pendingStatusesCount)")
          .accessibilityHint("accessibility.tabs.timeline.unread-posts.hint")
          .buttonStyle(.bordered)
          .background(.thinMaterial)
          .cornerRadius(8)
        }
        .padding(12)
      }
    }
    .onChange(of: userPreferences.showReplies) { _ in
      observer.refreshCount()
    }
  }
}
