import DesignSystem
import Env
import SwiftUI
import Account
import Network
import Models

@MainActor
struct AboutView: View {
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client

  @State private var dimillianAccount: AccountsListRowViewModel?
  @State private var iceCubesAccount: AccountsListRowViewModel?
  
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

      
      followAccountsSection

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

        • [SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols)
        """)
        .multilineTextAlignment(.leading)
        .font(.scaledSubheadline)
        .foregroundStyle(.secondary)
      } header: {
        Text("settings.about.built-with")
          .textCase(nil)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .task {
      await fetchAccounts()
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
  
  
  @ViewBuilder
  private var followAccountsSection: some View {
    if let iceCubesAccount, let dimillianAccount {
      Section {
        AccountsListRow(viewModel: iceCubesAccount)
        AccountsListRow(viewModel: dimillianAccount)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    } else {
      Section {
        ProgressView()
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private func fetchAccounts() async {
    await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        let viewModel = try await fetchAccountViewModel(account: "dimillian@mastodon.social")
        await MainActor.run {
          self.dimillianAccount = viewModel
        }
      }
      group.addTask {
        let viewModel = try await fetchAccountViewModel(account: "icecubesapp@mastodon.online")
        await MainActor.run {
          self.iceCubesAccount = viewModel
        }
      }
    }
  }
  
  private func fetchAccountViewModel(account: String) async throws -> AccountsListRowViewModel {
    let dimillianAccount: Account = try await client.get(endpoint: Accounts.lookup(name: account))
    let rel: [Relationship] = try await client.get(endpoint: Accounts.relationships(ids: [dimillianAccount.id]))
    return .init(account: dimillianAccount, relationShip: rel.first)
  }
}

struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    AboutView()
      .environment(Theme.shared)
  }
}
