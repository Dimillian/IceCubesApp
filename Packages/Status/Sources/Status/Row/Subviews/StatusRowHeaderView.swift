import DesignSystem
import Env
import Models
import SwiftUI

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
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Group {
            EmojiTextApp(.init(stringValue: status.account.safeDisplayName), emojis: status.account.emojis)
              .font(.scaledSubheadline)
              .emojiSize(Font.scaledSubheadlinePointSize)
              .fontWeight(.semibold)
              .lineLimit(1)
            accountBadgeView
              .font(.footnote)
          }
          .layoutPriority(1)
          if theme.avatarPosition == .leading {
            dateView
              .font(.scaledFootnote)
              .foregroundColor(.gray)
              .lineLimit(1)
          } else {
            Text("@\(theme.displayFullUsername ? status.account.acct : status.account.username)")
              .font(.scaledFootnote)
              .foregroundColor(.gray)
              .lineLimit(1)
          }
        }
        if theme.avatarPosition == .top {
          dateView
            .font(.scaledFootnote)
            .foregroundColor(.gray)
            .lineLimit(1)
        } else if theme.displayFullUsername, theme.avatarPosition == .leading {
          Text("@\(status.account.acct)")
            .font(.scaledFootnote)
            .foregroundColor(.gray)
            .lineLimit(1)
            .offset(y: 1)
        }
      }
    }
  }

  private var accountBadgeView: Text {
    if (viewModel.status.reblogAsAsStatus ?? viewModel.status).account.bot {
      return Text(Image(systemName: "gearshape.fill")) + Text(" ")
    } else if (viewModel.status.reblogAsAsStatus ?? viewModel.status).account.locked {
      return Text(Image(systemName: "lock.fill")) + Text(" ")
    }
    return Text("")
  }

  private var dateView: Text {
    Text(status.createdAt.relativeFormatted) +
      Text(" ⸱ ") +
      Text(Image(systemName: viewModel.status.visibility.iconName))
  }

  @ViewBuilder
  private var threadIcon: some View {
    if viewModel.isThread {
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
        .frame(width: 20, height: 20)
    }
    .menuStyle(.borderlessButton)
    .foregroundColor(.gray)
    .contentShape(Rectangle())
    .accessibilityHidden(true)
  }
}
