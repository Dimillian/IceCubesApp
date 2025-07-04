import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
struct NotificationRowAvatarView: View {
  let account: Account
  let notificationType: Models.Notification.NotificationType
  let status: Status?
  let routerPath: RouterPath

  var body: some View {
    ZStack(alignment: .topLeading) {
      AvatarView(account.avatar)
      if #available(iOS 26.0, *) {
        NotificationRowIconView(
          type: notificationType,
          status: status,
          showBorder: false
        )
        .frame(
          width: AvatarView.FrameConfig.status.width / 1.7,
          height: AvatarView.FrameConfig.status.height / 1.7,
        )
        .glassEffect(
          .regular.tint(notificationType.tintColor(isPrivate: status?.visibility == .direct))
        )
        .offset(x: -8, y: -8)
      } else {
        NotificationRowIconView(
          type: notificationType,
          status: status,
          showBorder: false
        )
        .offset(x: -8, y: -8)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routerPath.navigate(to: .accountDetailWithAccount(account: account))
    }
  }
}
