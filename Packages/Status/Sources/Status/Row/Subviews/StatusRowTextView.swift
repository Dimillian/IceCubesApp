import DesignSystem
import Models
import SwiftUI

struct StatusRowTextView: View {
  @EnvironmentObject private var theme: Theme
  
  let status: AnyStatus
  let viewModel: StatusRowViewModel

  var body: some View {
    HStack {
      EmojiTextApp(status.content, emojis: status.emojis, language: status.language)
        .font(.scaledBody)
        .environment(\.openURL, OpenURLAction { url in
          viewModel.routerPath.handleStatus(status: status, url: url)
        })
      Spacer()
    }
  }
}
