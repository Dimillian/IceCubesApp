import SwiftUI
import Network

@MainActor
public extension View {
  func withPreviewsEnv() -> some View{
    environment(RouterPath())
    .environment(Client(server: ""))
    .environment(CurrentAccount.shared)
    .environment(UserPreferences.shared)
    .environment(CurrentInstance.shared)
    .environment(PushNotificationsService.shared)
    .environment(QuickLook.shared)
  }
}
