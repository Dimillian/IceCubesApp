import DesignSystem
import Env
import Models
import SwiftUI

struct StatusRowTextView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var preferences: UserPreferences

  let status: AnyStatus
  @ObservedObject var viewModel: StatusRowViewModel
  
  var body: some View {
    VStack {
      HStack {
        EmojiTextApp(status.content, emojis: status.emojis, language: status.language, lineLimit: viewModel.lineLimit)
          .font(.scaledBody)
          .emojiSize(Font.scaledBodyPointSize)
          .environment(\.openURL, OpenURLAction { url in
            viewModel.routerPath.handleStatus(status: status, url: url)
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
