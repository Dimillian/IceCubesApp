import SwiftUI
import Timeline
import Account
import Routeur

extension View {
  func withAppRouteur() -> some View {
    self.navigationDestination(for: RouteurDestinations.self) { destination in
      switch destination {
      case let .accountDetail(id):
        AccountDetailView(accountId: id)
      case let .statusDetail(id):
        StatusDetailView(statusId: id)
      }
    }
  }
}
