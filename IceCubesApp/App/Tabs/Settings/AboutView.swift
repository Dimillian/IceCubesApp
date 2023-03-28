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
    List {
      Section {
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

        Link(destination: URL(string: "https://github.com/Dimillian/IceCubesApp/blob/main/PRIVACY.MD")!) {
          Label("settings.support.privacy-policy", systemImage: "lock")
        }

        Link(destination: URL(string: "https://github.com/Dimillian/IceCubesApp/blob/main/TERMS.MD")!) {
          Label("settings.support.terms-of-use", systemImage: "checkmark.shield")
        }
      } footer: {
        Text("\(versionNumber)©2023 Thomas Ricouard")
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Text("""
        • [EmojiText](https://github.com/divadretlaw/EmojiText)

        • [HTML2Markdown](https://gitlab.com/mflint/HTML2Markdown)

        • [KeychainSwift](https://github.com/evgenyneu/keychain-swift)

        • [LRUCache](https://github.com/nicklockwood/LRUCache)

        • [Bodega](https://github.com/mergesort/Bodega)

        • [Nuke](https://github.com/kean/Nuke)

        • [SwiftSoup](https://github.com/scinfu/SwiftSoup.git)

        • [Atkinson Hyperlegible](https://github.com/googlefonts/atkinson-hyperlegible)

        • [OpenDyslexic](http://opendyslexic.org)

        • [SwiftUI-Introspect](https://github.com/siteline/SwiftUI-Introspect)

        • [RevenueCat](https://github.com/RevenueCat/purchases-ios)
        """)
        .multilineTextAlignment(.leading)
        .font(.scaledSubheadline)
        .foregroundColor(.gray)
      } header: {
        Text("settings.about.built-with")
          .textCase(nil)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .listStyle(.insetGrouped)
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
      .environmentObject(Theme.shared)
  }
}
