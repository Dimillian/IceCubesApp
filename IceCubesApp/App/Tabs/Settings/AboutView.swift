import DesignSystem
import Env
import SwiftUI

struct AboutView: View {
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var theme: Theme

  let versionNumber: String

  init() {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      versionNumber = version + " "
    } else {
      versionNumber = ""
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Divider()
        HStack {
          Spacer()
          Image("icon0")
            .resizable()
            .frame(width: 50, height: 50)
            .cornerRadius(4)
          Image("icon14")
            .resizable()
            .frame(width: 50, height: 50)
            .cornerRadius(4)
          Image("icon17")
            .resizable()
            .frame(width: 50, height: 50)
            .cornerRadius(4)
          Image("icon23")
            .resizable()
            .frame(width: 50, height: 50)
            .cornerRadius(4)
          Spacer()
        }
        .padding(.top, 10)
        HStack {
          Spacer()
          Text("\(versionNumber)©2023 Thomas Ricouard")
            .font(.scaledFootnote)
            .foregroundColor(.gray)
            .fontWeight(.semibold)
            .padding(.bottom, 10)
          Spacer()
        }
        Divider()
        Text("settings.about.built-with")
          .padding(.horizontal, 25)
          .padding(.bottom, 10)
          .font(.scaledSubheadline)
          .foregroundColor(.gray)
        Text("""
        • [EmojiText](https://github.com/divadretlaw/EmojiText)

        • [HTML2Markdown](https://gitlab.com/mflint/HTML2Markdown)

        • [KeychainSwift](https://github.com/evgenyneu/keychain-swift)

        • [LRUCache](https://github.com/nicklockwood/LRUCache)
        
        • [Boutique](https://github.com/mergesort/Boutique)

        • [Nuke](https://github.com/kean/Nuke)

        • [SwiftSoup](https://github.com/scinfu/SwiftSoup.git)

        • [Atkinson Hyperlegible](https://github.com/googlefonts/atkinson-hyperlegible)

        • [OpenDyslexic](http://opendyslexic.org)
        """)
        .padding(.horizontal, 25)
        .multilineTextAlignment(.leading)
        .font(.scaledSubheadline)
        .foregroundColor(.gray)
      }
      Divider()
      Spacer()
    }
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .navigationTitle(Text("settings.about.title"))
    .navigationBarTitleDisplayMode(.large)
    .environment(\.openURL, OpenURLAction { url in
      routerPath.handle(url: url)
    })
  }
}

struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    AboutView()
  }
}
