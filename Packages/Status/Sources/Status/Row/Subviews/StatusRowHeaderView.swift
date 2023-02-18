import DesignSystem
import Models
import SwiftUI

struct StatusRowHeaderView: View {
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
      threadIcon
      contextMenuButton
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
      VStack(alignment: .leading, spacing: 0) {
        EmojiTextApp(.init(stringValue: status.account.safeDisplayName), emojis: status.account.emojis)
          .font(.scaledSubheadline)
          .fontWeight(.semibold)
        Group {
          Text("@\(status.account.acct)") +
            Text(" ⸱ ") +
            Text(status.createdAt.relativeFormatted) +
            Text(" ⸱ ") +
            Text(Image(systemName: viewModel.status.visibility.iconName))
        }
        .font(.scaledFootnote)
        .foregroundColor(.gray)
      }
    }
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
        .frame(width: 20, height: 30)
    }
    .menuStyle(.borderlessButton)
    .foregroundColor(.gray)
    .contentShape(Rectangle())
    .accessibilityHidden(true)
  }
}
