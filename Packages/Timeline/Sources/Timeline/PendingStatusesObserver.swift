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
