import DesignSystem
import Models
import Network
import SwiftUI
import Timeline
import WidgetKit

struct AccountWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in _: Context) -> AccountWidgetEntry {
    .init(date: Date(), account: .placeholder(), avatar: nil)
  }

  func snapshot(for configuration: AccountWidgetConfiguration, in context: Context) async -> AccountWidgetEntry {
    let account = await fetchAccount(configuration: configuration)
    return .init(date: Date(), account: account, avatar: nil)
  }

  func timeline(for configuration: AccountWidgetConfiguration, in context: Context) async -> Timeline<AccountWidgetEntry> {
    let account = await fetchAccount(configuration: configuration)
    let images = try? await loadImages(urls: [account.avatar])
    return .init(entries: [.init(date: Date(), account: account, avatar: images?.first?.value)],
                 policy: .atEnd)
  }
  
  private func fetchAccount(configuration: AccountWidgetConfiguration) async -> Account {
    let client = Client(server: configuration.account.account.server,
                        oauthToken: configuration.account.account.oauthToken)
    do {
      let account: Account = try await client.get(endpoint: Accounts.verifyCredentials)
      return account
    } catch {
      return .placeholder()
    }
  }
}

struct AccountWidgetEntry: TimelineEntry {
  let date: Date
  let account: Account
  let avatar: UIImage?
}

struct AccountWidget: Widget {
  let kind: String = "AccountWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind,
                           intent: AccountWidgetConfiguration.self,
                           provider: AccountWidgetProvider())
    { entry in
      AccountWidgetView(entry: entry)
        .containerBackground(Color("WidgetBackground").gradient, for: .widget)
    }
    .configurationDisplayName("Account")
    .description("Show information about your Mastodon account")
    .supportedFamilies([.systemSmall])
  }
}

#Preview(as: .systemSmall) {
  AccountWidget()
} timeline: {
  AccountWidgetEntry(date: Date(), account: .placeholder(), avatar: nil)
}
