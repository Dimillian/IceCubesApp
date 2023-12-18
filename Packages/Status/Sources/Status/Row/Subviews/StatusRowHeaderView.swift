import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct StatusRowHeaderView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.isStatusFocused) private var isFocused

  @Environment(Theme.self) private var theme

  let viewModel: StatusRowViewModel
  @State private var showTextForSelection: Bool = false

  var body: some View {
    HStack(alignment: .center) {
      Button {
        viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
      } label: {
        accountView
      }
      .buttonStyle(.plain)
      Spacer()
      if !isInCaptureMode {
        threadIcon
        contextMenuButton
      }
    }
    .sheet(isPresented: $showTextForSelection) {
      let content = viewModel.status.reblog?.content.asSafeMarkdownAttributedString ?? viewModel.status.content.asSafeMarkdownAttributedString
      SelectTextView(content: content)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text("\(viewModel.finalStatus.account.safeDisplayName)") + Text(", ") + Text(viewModel.finalStatus.createdAt.relativeFormatted))
    .accessibilityAction {
      viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
    }
    .accessibilityActions {
      if isFocused {
        StatusRowContextMenu(viewModel: viewModel, showTextForSelection: $showTextForSelection)
      }
    }
  }

  @ViewBuilder
  private var accountView: some View {
    HStack(alignment: .center) {
      if theme.avatarPosition == .top {
        AvatarView(viewModel.finalStatus.account.avatar)
          .accountPopover(viewModel.finalStatus.account)
      }
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Group {
            EmojiTextApp(.init(stringValue: viewModel.finalStatus.account.safeDisplayName),
                         emojis: viewModel.finalStatus.account.emojis)
              .font(.scaledSubheadline)
              .foregroundColor(theme.labelColor)
              .emojiSize(Font.scaledSubheadlineFont.emojiSize)
              .emojiBaselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
              .fontWeight(.semibold)
              .lineLimit(1)
              .accountPopover(viewModel.finalStatus.account)

            accountBadgeView
              .font(.footnote)
          }
          .layoutPriority(1)
          if theme.avatarPosition == .leading {
            dateView
              .font(.scaledFootnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          } else {
            Text("@\(theme.displayFullUsername ? viewModel.finalStatus.account.acct : viewModel.finalStatus.account.username)")
              .font(.scaledFootnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .accountPopover(viewModel.finalStatus.account)
          }
        }
        if theme.avatarPosition == .top {
          dateView
            .font(.scaledFootnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        } else if theme.displayFullUsername, theme.avatarPosition == .leading {
          Text("@\(viewModel.finalStatus.account.acct)")
            .font(.scaledFootnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .offset(y: 1)
            .accountPopover(viewModel.finalStatus.account)
        }
      }
    }
  }

  private var accountBadgeView: Text {
    if (viewModel.status.reblogAsAsStatus ?? viewModel.status).account.bot {
      return Text(Image(systemName: "poweroutlet.type.b.fill")) + Text(" ")
    } else if (viewModel.status.reblogAsAsStatus ?? viewModel.status).account.locked {
      return Text(Image(systemName: "lock.fill")) + Text(" ")
    }
    return Text("")
  }

  private var dateView: Text {
    Text(viewModel.finalStatus.createdAt.relativeFormatted) +
      Text(" ⸱ ") +
      Text(Image(systemName: viewModel.finalStatus.visibility.iconName))
  }

  @ViewBuilder
  private var threadIcon: some View {
    if viewModel.isThread {
      Image(systemName: "bubble.left.and.bubble.right")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 15)
        .foregroundStyle(.secondary)
    }
  }

  private var contextMenuButton: some View {
    Menu {
      StatusRowContextMenu(viewModel: viewModel, showTextForSelection: $showTextForSelection)
        .onAppear {
          Task {
            await viewModel.loadAuthorRelationship()
          }
        }
    } label: {
      Image(systemName: "ellipsis")
        .frame(width: 40, height: 40)
    }
    .menuStyle(.borderlessButton)
    .foregroundStyle(.secondary)
    .contentShape(Rectangle())
    .accessibilityHidden(true)
  }
}
