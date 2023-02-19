import DesignSystem
import Models
import SwiftUI
import Env

struct StatusRowHeaderView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @EnvironmentObject private var theme: Theme

  let status: AnyStatus
  let viewModel: StatusRowViewModel

  var body: some View {
    HStack(alignment: .center) {
      Button {
        viewModel.navigateToAccountDetail(account: status.account)
      } label: {
        accountView(status: status)
      }
      .buttonStyle(.plain)
      Spacer()
      if !isInCaptureMode {
        threadIcon
        contextMenuButton
      }
    }
    .accessibilityElement()
    .accessibilityLabel(Text("\(status.account.displayName)"))
  }

  @ViewBuilder
  private func accountView(status: AnyStatus) -> some View {
    HStack(alignment: .center) {
      if theme.avatarPosition == .top {
        AvatarView(url: status.account.avatar, size: .status)
      }
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .center, spacing: 4) {
          EmojiTextApp(.init(stringValue: status.account.safeDisplayName), emojis: status.account.emojis)
            .font(.scaledSubheadline)
            .fontWeight(.semibold)
            .lineLimit(1)
          if theme.avatarPosition == .leading {
            dateView
              .offset(y: 1)
              .lineLimit(1)
          }
        }
        if theme.avatarPosition == .top {
          HStack(spacing: 0) {
            Text("@\(theme.displayFullUsername ? status.account.acct : status.account.username)") +
            Text(" ⸱ ") +
            dateView
          }
          .font(.scaledFootnote)
          .foregroundColor(.gray)
          .lineLimit(1)
        }
      }
    }
  }
  
  private var dateView: Text {
    Text(status.createdAt.relativeFormatted) +
    Text(" ⸱ ") +
    Text(Image(systemName: viewModel.status.visibility.iconName))
      .font(.scaledFootnote)
      .foregroundColor(.gray)
  }

  @ViewBuilder
  private var threadIcon: some View {
    if viewModel.status.reblog?.inReplyToAccountId != nil || viewModel.status.inReplyToAccountId != nil {
      Image(systemName: "bubble.left.and.bubble.right")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 15)
        .foregroundColor(.gray)
    }
  }

  private var contextMenuButton: some View {
    Menu {
      StatusRowContextMenu(viewModel: viewModel)
    } label: {
      Image(systemName: "ellipsis")
        .frame(width: 20)
    }
    .menuStyle(.borderlessButton)
    .foregroundColor(.gray)
    .contentShape(Rectangle())
    .accessibilityHidden(true)
  }
}
