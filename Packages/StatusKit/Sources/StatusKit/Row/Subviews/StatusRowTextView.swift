import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct StatusRowTextView: View {
  @Environment(Theme.self) private var theme
  @Environment(\.isStatusFocused) private var isFocused
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(\.isNotificationsTab) private var isNotificationsTab

  @Environment(StatusDataController.self) private var statusDataController

  var viewModel: StatusRowViewModel

  var body: some View {
    VStack {
      HStack {
        EmojiTextApp(
          statusDataController.content,
          emojis: viewModel.finalStatus.emojis,
          language: viewModel.finalStatus.language,
          lineLimit: isNotificationsTab
            ? (userPreferences.notificationsTruncateStatusContent ? 2 : nil)
            : (viewModel.textDisabled ? 3 : viewModel.lineLimit)
        )
        .fixedSize(horizontal: false, vertical: true)
        .font(isFocused ? .scaledBodyFocused : .scaledBody)
        .lineSpacing(CGFloat(theme.lineSpacing))
        .foregroundColor(viewModel.textDisabled ? .gray : theme.labelColor)
        .emojiText.size(
          isFocused ? Font.scaledBodyFocusedFont.emojiSize : Font.scaledBodyFont.emojiSize
        )
        .emojiText.baselineOffset(
          isFocused
            ? Font.scaledBodyFocusedFont.emojiBaselineOffset
            : Font.scaledBodyFont.emojiBaselineOffset
        )
        .environment(
          \.openURL,
          OpenURLAction { url in
            viewModel.routerPath.handleStatus(status: viewModel.finalStatus, url: url)
          })
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      makeCollapseButton()
    }
  }

  @ViewBuilder
  func makeCollapseButton() -> some View {
    if viewModel.lineLimit != nil {
      HStack(alignment: .top) {
        Text("status.show-full-post")
          .font(.system(.subheadline, weight: .bold))
          .foregroundColor(.secondary)
        Spacer()
        Button {
          withAnimation {
            viewModel.isCollapsed.toggle()
          }
        } label: {
          Image(systemName: "chevron.down")
        }
        .buttonStyle(.bordered)
        .accessibility(label: Text("status.show-full-post"))
        .accessibilityHidden(true)
      }
      .contentShape(Rectangle())
      .onTapGesture {  // make whole row tapable to make up for smaller button size
        withAnimation {
          viewModel.isCollapsed.toggle()
        }
      }
    }
  }
}
