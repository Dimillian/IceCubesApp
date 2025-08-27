import DesignSystem
import EmojiText
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
struct NotificationRowMainLabelView: View {
  @Environment(\.redactionReasons) private var reasons

  let notification: ConsolidatedNotification
  let routerPath: RouterPath

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if notification.accounts.count > 1 {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 8) {
            ForEach(notification.accounts) { account in
              AvatarView(account.avatar)
                .contentShape(Rectangle())
                .onTapGesture {
                  routerPath.navigate(to: .accountDetailWithAccount(account: account))
                }
            }
          }
          .padding(.leading, 1)
          .frame(height: AvatarView.FrameConfig.status.size.height + 2)
        }
        .offset(y: -1)
      }
      if !reasons.contains(.placeholder) {
        HStack(spacing: 0) {
          EmojiTextApp(
            .init(stringValue: notification.accounts[0].safeDisplayName),
            emojis: notification.accounts[0].emojis,
            append: { NotificationRowAppendTextView(notification: notification) }
          )
          .font(.scaledSubheadline)
          .emojiText.size(Font.scaledSubheadlineFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
          .fontWeight(.semibold)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
          if let status = notification.status, notification.type == .mention {
            Group {
              Text(" ⸱ ")
              Text(Image(systemName: status.visibility.iconName))
            }
            .accessibilityHidden(true)
            .font(.scaledFootnote)
            .fontWeight(.regular)
            .foregroundStyle(.secondary)
          }
          Spacer()
        }
      } else {
        Text("          ")
          .font(.scaledSubheadline)
          .fontWeight(.semibold)
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
    .accessibilityElement(children: .combine)
  }
}
