import Foundation
import SwiftUI
import Models

@MainActor
class PendingStatusesObserver: ObservableObject {
  @Published var pendingStatusesCount: Int = 0
  
  var pendingStatuses: [String] = [] {
    didSet {
      pendingStatusesCount = pendingStatuses.count
    }
  }
  
  func removeStatus(status: Status) {
    if let index = pendingStatuses.firstIndex(of: status.id) {
      pendingStatuses.removeSubrange(index...(pendingStatuses.count - 1))
    }
  }
  
  init() { }
}

struct PendingStatusesObserverView: View {
  @ObservedObject var observer: PendingStatusesObserver
  @State var proxy: ScrollViewProxy
  
  var body: some View {
    if observer.pendingStatusesCount > 0 {
      HStack(spacing: 6) {
        Spacer()
        Button {
          withAnimation {
            proxy.scrollTo(observer.pendingStatuses.last, anchor: .bottom)
          }
        } label: {
          Text("\(observer.pendingStatusesCount)")
        }
        .buttonStyle(.bordered)
        .background(.thinMaterial)
        .cornerRadius(8)
      }
      .padding(12)
    }
  }
}
