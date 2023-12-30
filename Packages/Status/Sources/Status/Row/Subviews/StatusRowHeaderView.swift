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

  let viewModel: StatusRowViewModel
  var body: some View {
    HStack(alignment: theme.avatarPosition == .top ? .center : .top) {
      Button {
        viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
      } label: {
        accountView
      }
      .buttonStyle(.plain)
      Spacer()
      if !redactionReasons.contains(.placeholder) {
        dateView
      }
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
              .font(.scaledSubheadline)
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
      Text(Image(systemName: viewModel.finalStatus.visibility.iconName)) +
      Text(" ⸱ ") +
      Text(viewModel.finalStatus.createdAt.relativeFormatted)
    }
    .font(.scaledFootnote)
    .foregroundStyle(.secondary)
    .lineLimit(1)
  }
}
