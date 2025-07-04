import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

struct NotificationsRequestsRowView: View {
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client

  let request: NotificationsRequest

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      AvatarView(request.account.avatar, config: .embed)

      VStack(alignment: .leading) {
        EmojiTextApp(request.account.cachedDisplayName, emojis: request.account.emojis)
          .font(.scaledBody)
          .foregroundStyle(theme.labelColor)
          .lineLimit(1)
        Text(request.account.acct)
          .font(.scaledFootnote)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .padding(.vertical, 4)
      Spacer()
      Text(request.notificationsCount)
        .font(.footnote)
        .monospacedDigit()
        .foregroundStyle(theme.primaryBackgroundColor)
        .padding(8)
        .background(.secondary)
        .clipShape(Circle())

      Image(systemName: "chevron.right")
        .foregroundStyle(.secondary)
    }
  }
}
