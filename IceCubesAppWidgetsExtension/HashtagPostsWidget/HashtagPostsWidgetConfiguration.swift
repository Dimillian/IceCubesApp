import AppIntents
import WidgetKit

struct HashtagPostsWidgetConfiguration: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Configuration"
  static let description = IntentDescription("Choose the account and hashtag for this widget")

  @Parameter(title: "Account")
  var account: AppAccountEntity

  @Parameter(title: "Hashtag")
  var hashgtag: String
}

extension HashtagPostsWidgetConfiguration {
  static var previewAccount: HashtagPostsWidgetConfiguration {
    let intent = HashtagPostsWidgetConfiguration()
    intent.account = .init(account: .init(server: "Test", accountName: "Test account"))
    intent.hashgtag = "Mastodon"
    return intent
  }
}
