import DesignSystem
import EmojiText
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

@MainActor
struct NotificationRowView: View {
  @Environment(Theme.self) private var theme
  @Environment(\.redactionReasons) private var reasons

  let notification: ConsolidatedNotification
  let client: MastodonClient
  let routerPath: RouterPath
  let followRequests: [Account]

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      if notification.accounts.count == 1 {
        NotificationRowAvatarView(
          account: notification.accounts[0],
          notificationType: notification.type,
          status: notification.status,
          routerPath: routerPath
        )
        .accessibilityHidden(true)
      } else {
        if #available(iOS 26.0, *) {
          NotificationRowIconView(
            type: notification.type,
            status: notification.status,
            showBorder: false
          )
          .frame(
            width: AvatarView.FrameConfig.status.width,
            height: AvatarView.FrameConfig.status.height
          )
          .accessibilityHidden(true)
          .glassEffect(
            .regular.tint(
              notification.type.tintColor(isPrivate: notification.status?.visibility == .direct)))
        } else {
          NotificationRowIconView(
            type: notification.type,
            status: notification.status,
            showBorder: true
          )
          .frame(
            width: AvatarView.FrameConfig.status.width,
            height: AvatarView.FrameConfig.status.height
          )
          .accessibilityHidden(true)
        }
      }
      VStack(alignment: .leading, spacing: 0) {
        NotificationRowMainLabelView(
          notification: notification,
          routerPath: routerPath
        )
        // The main label is redundant for mentions
        .accessibilityHidden(notification.type == .mention)
        .padding(.trailing, -.layoutPadding)
        NotificationRowContentView(
          notification: notification,
          client: client,
          routerPath: routerPath
        )
      .environment(\.isNotificationsTab, true)
        if notification.type == .follow_request,
          followRequests.map(\.id).contains(notification.accounts[0].id)
        {
          FollowRequestButtons(account: notification.accounts[0])
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityActions {
      if notification.type == .follow {
        NotificationRowAccessibilityActionsView(
          accounts: notification.accounts,
          routerPath: routerPath
        )
      }
    }
    .alignmentGuide(.listRowSeparatorLeading) { _ in
      -100
    }
  }
}
