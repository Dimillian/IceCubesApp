import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
struct StatusRowHeaderView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.isStatusFocused) private var isFocused
  @Environment(\.redactionReasons) private var redactionReasons

  @Environment(Theme.self) private var theme

  let viewModel: StatusRowViewModel
  var body: some View {
    HStack(alignment: theme.avatarPosition == .top ? .center : .top) {
      accountView
        .hoverEffect()
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
          viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
        }
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
        #if targetEnvironment(macCatalyst)
          .accountPopover(viewModel.finalStatus.account)
        #endif
      }
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Group {
            EmojiTextApp(viewModel.finalStatus.account.cachedDisplayName,
                         emojis: viewModel.finalStatus.account.emojis)
              .font(.scaledSubheadline)
              .foregroundColor(theme.labelColor)
              .emojiText.size(Font.scaledSubheadlineFont.emojiSize)
              .emojiText.baselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
              .fontWeight(.semibold)
              .lineLimit(1)
            #if targetEnvironment(macCatalyst)
              .accountPopover(viewModel.finalStatus.account)
            #endif

            if !redactionReasons.contains(.placeholder) {
              accountBadgeView
                .font(.footnote)
            }
          }
          .layoutPriority(1)
        }
        if !redactionReasons.contains(.placeholder) {
          if (theme.displayFullUsername && theme.avatarPosition == .leading) ||
            theme.avatarPosition == .top
          {
            Text("@\(theme.displayFullUsername ? viewModel.finalStatus.account.acct : viewModel.finalStatus.account.username)")
              .font(.scaledFootnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            #if targetEnvironment(macCatalyst)
              .accountPopover(viewModel.finalStatus.account)
            #endif
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
