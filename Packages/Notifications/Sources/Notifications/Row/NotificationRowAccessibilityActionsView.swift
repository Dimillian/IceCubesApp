import DesignSystem
import Models
import NetworkClient
import Env
import SwiftUI

@MainActor
struct NotificationRowAccessibilityActionsView: View {
  let accounts: [Account]
  let routerPath: RouterPath

  var body: some View {
    ForEach(accounts) { account in
      Button("@\(account.username)") {
        HapticManager.shared.fireHaptic(.notification(.success))
        routerPath.navigate(to: .accountDetail(id: account.id))
      }
    }
  }
}
