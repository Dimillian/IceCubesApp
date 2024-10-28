import Network
import SwiftUI

@MainActor
extension View {
  public func withPreviewsEnv() -> some View {
    environment(RouterPath())
      .environment(Client(server: ""))
      .environment(CurrentAccount.shared)
      .environment(UserPreferences.shared)
      .environment(CurrentInstance.shared)
      .environment(PushNotificationsService.shared)
      .environment(QuickLook.shared)
  }
}
