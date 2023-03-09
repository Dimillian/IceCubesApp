import DesignSystem
import Env
import Models
import SwiftUI

struct StatusRowTextView: View {
  @EnvironmentObject private var theme: Theme

  @ObservedObject var viewModel: StatusRowViewModel
  
  var body: some View {
    VStack {
      HStack {
        EmojiTextApp(viewModel.finalStatus.content,
                     emojis: viewModel.finalStatus.emojis,
                     language: viewModel.finalStatus.language,
                     lineLimit: viewModel.lineLimit)
          .font(viewModel.isFocused ? .scaledBodyFocused : .scaledBody)
          .foregroundColor(viewModel.textDisabled ? .gray : theme.labelColor)
          .emojiSize(viewModel.isFocused ? Font.scaledBodyFocusedFont.emojiSize : Font.scaledBodyFont.emojiSize)
          .emojiBaselineOffset(viewModel.isFocused ? Font.scaledBodyFocusedFont.emojiBaselineOffset : Font.scaledBodyFont.emojiBaselineOffset)
          .environment(\.openURL, OpenURLAction { url in
            viewModel.routerPath.handleStatus(status: viewModel.finalStatus, url: url)
          })
        Spacer()
      }
      makeCollapseButton()
    }
  }

  @ViewBuilder
  func makeCollapseButton() -> some View {
    if let _ = viewModel.lineLimit {
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
      .onTapGesture { // make whole row tapable to make up for smaller button size
        withAnimation {
          viewModel.isCollapsed.toggle()
        }
      }
    }
  }
}
