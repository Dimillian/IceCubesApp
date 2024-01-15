import DesignSystem
import Env
import Models
import SwiftUI
import Network

@MainActor
struct StatusRowHeaderView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.isStatusFocused) private var isFocused
  @Environment(\.redactionReasons) private var redactionReasons

  @Environment(Theme.self) private var theme

  @Binding var showTextForSelection: Bool

  let viewModel: StatusRowViewModel
  var body: some View {
    HStack()
    {
      VStack(alignment: .leading, spacing: 0) {
        Button {
          viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
        } label: {
          accountView
        }
        .buttonStyle(.plain)

        if !redactionReasons.contains(.placeholder) {
          dateView
        }
      }
      Spacer()

      Menu {
        StatusRowContextMenu(viewModel: viewModel, showTextForSelection: $showTextForSelection)
          .onAppear {
            Task {
              await viewModel.loadAuthorRelationship()
            }
          }
      } label: {
        Label("", systemImage: "ellipsis")
          .padding(.vertical, 6)
      }
      .menuStyle(.button)
      .buttonStyle(.borderless)
      .contentShape(Rectangle())
      .accessibilityLabel("status.action.context-menu")
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text("\(viewModel.finalStatus.account.safeDisplayName)") + Text(", ") + Text(viewModel.finalStatus.createdAt.relativeFormatted))
    .accessibilityAction {
      viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
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
              .foregroundColor(theme.labelColor)
              .emojiSize(Font.scaledSubheadlineFont.emojiSize)
              .emojiBaselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
              .fontWeight(.semibold)
              .lineLimit(1)
              .accountPopover(viewModel.finalStatus.account)

            if !redactionReasons.contains(.placeholder) {
              accountBadgeView
                .font(.footnote)
            }
          }
          .layoutPriority(1)
        }
        if !redactionReasons.contains(.placeholder) {
         if (theme.displayFullUsername && theme.avatarPosition == .leading) ||
              theme.avatarPosition == .top {
           Text("@\(theme.displayFullUsername ? viewModel.finalStatus.account.acct : viewModel.finalStatus.account.username)")
             .font(.scaledFootnote)
             .foregroundStyle(.secondary)
             .lineLimit(1)
             .accountPopover(viewModel.finalStatus.account)
         }
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

  private var dateView: some View {
    Group {
      Text(viewModel.finalStatus.createdAt.relativeFormatted) +
      Text(" - ") +
      Text("@\(viewModel.finalStatus.account.acct)")
    }
    .foregroundStyle(.secondary)
    .lineLimit(2)
  }
}
