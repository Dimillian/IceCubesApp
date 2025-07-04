import DesignSystem
import EmojiText
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct StatusEmbeddedView: View {
  @Environment(Theme.self) private var theme

  public let status: Status
  public let client: MastodonClient
  public let routerPath: RouterPath

  public init(status: Status, client: MastodonClient, routerPath: RouterPath) {
    self.status = status
    self.client = client
    self.routerPath = routerPath
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        makeAccountView(account: status.reblog?.account ?? status.account)
        StatusRowView(
          viewModel: .init(
            status: status,
            client: client,
            routerPath: routerPath,
            showActions: false),
          context: .timeline
        )
        .accessibilityLabel(status.content.asRawText)
        .environment(\.isCompact, true)
        .environment(\.isMediaCompact, true)
        .environment(\.isStatusFocused, false)
      }
      Spacer()
    }
    .padding(8)
    #if os(visionOS)
      .background(Material.thickMaterial)
    #else
      .background(theme.secondaryBackgroundColor)
    #endif
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
      AvatarView(account.avatar, config: .embed)
      VStack(alignment: .leading, spacing: 0) {
        EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
          .font(.scaledFootnote)
          .emojiText.size(Font.scaledFootnoteFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
          .fontWeight(.semibold)
        Group {
          Text("@\(account.acct)") + Text(" ⸱ ")
            + Text(status.reblog?.createdAt.relativeFormatted ?? status.createdAt.relativeFormatted)
        }
        .font(.scaledCaption)
        .foregroundStyle(.secondary)
      }
    }
  }
}
