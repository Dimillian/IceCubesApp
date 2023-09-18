import DesignSystem
import EmojiText
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct StatusEmbeddedView: View {
  @EnvironmentObject private var theme: Theme

  public let status: Status
  public let client: Client
  public let routerPath: RouterPath

  public init(status: Status, client: Client, routerPath: RouterPath) {
    self.status = status
    self.client = client
    self.routerPath = routerPath
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        makeAccountView(account: status.reblog?.account ?? status.account)
        StatusRowView(viewModel: .init(status: status,
                                       client: client,
                                       routerPath: routerPath,
                                       showActions: false))
          .accessibilityLabel(status.content.asRawText)
          .environment(\.isCompact, true)
      }
      Spacer()
    }
    .padding(8)
    .background(theme.secondaryBackgroundColor)
    .cornerRadius(4)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(.gray.opacity(0.35), lineWidth: 1)
    )
    .padding(.top, 8)
    .accessibilityElement(children: .combine)
  }

  private func makeAccountView(account: Account) -> some View {
    HStack(alignment: .center) {
      AvatarView(url: account.avatar, size: .embed)
      VStack(alignment: .leading, spacing: 0) {
        EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
          .font(.scaledFootnote)
          .emojiSize(Font.scaledFootnoteFont.emojiSize)
          .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
          .fontWeight(.semibold)
        Group {
          Text("@\(account.acct)") +
            Text(" ⸱ ") +
            Text(status.reblog?.createdAt.relativeFormatted ?? status.createdAt.relativeFormatted)
        }
        .font(.scaledCaption)
        .foregroundColor(.gray)
      }
    }
  }
}
