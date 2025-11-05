import DesignSystem
import EmojiText
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

@MainActor
struct NotificationRowContentView: View {
  let notification: ConsolidatedNotification
  let client: MastodonClient
  let routerPath: RouterPath

  var body: some View {
    if let status = notification.status {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 8) {
          if notification.type == .mention {
            StatusRowExternalView(
              viewModel: .init(
                status: status,
                client: client,
                routerPath: routerPath,
                showActions: true)
            )
            .environment(\.isNotificationsTab, false)
            .environment(\.isMediaCompact, false)
          } else {
            StatusRowExternalView(
              viewModel: .init(
                status: status,
                client: client,
                routerPath: routerPath,
                showActions: false,
                textDisabled: notification.type != .quote)
            )
            .environment(\.isMediaCompact, true)
          }

          if notification.type == .quote,
            status.quote?.state == .accepted,
            let quotedStatus = status.quote?.quotedStatus
          {
            StatusEmbeddedView(
              status: quotedStatus,
              client: client,
              routerPath: routerPath
            )
            .padding(.bottom, 8)
          }
        }
        Spacer()
      }
      .environment(\.isCompact, true)
    } else {
      Group {
        Text("@\(notification.accounts[0].acct)")
          .font(.scaledCallout)
          .foregroundStyle(.secondary)

        if notification.type == .follow {
          EmojiTextApp(
            notification.accounts[0].note,
            emojis: notification.accounts[0].emojis
          )
          .accessibilityLabel(notification.accounts[0].note.asRawText)
          .lineLimit(3)
          .font(.scaledCallout)
          .emojiText.size(Font.scaledCalloutFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledCalloutFont.emojiBaselineOffset)
          .foregroundStyle(.secondary)
          .environment(
            \.openURL,
            OpenURLAction { url in
              routerPath.handle(url: url)
            }
          )
          .accessibilityAddTraits(.isButton)
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        if notification.accounts.count == 1 {
          routerPath.navigate(to: .accountDetailWithAccount(account: notification.accounts[0]))
        } else {
          routerPath.navigate(to: .accountsList(accounts: notification.accounts))
        }
      }
    }
  }
}
