import AppIntents
import WidgetKit

struct ListsWidgetConfiguration: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Configuration"
  static let description = IntentDescription("Choose the account and list for this widget")

  @Parameter(title: "Account")
  var account: AppAccountEntity

  @Parameter(title: "List")
  var timeline: ListEntity
}

extension ListsWidgetConfiguration {
  static var previewAccount: LatestPostsWidgetConfiguration {
    let intent = LatestPostsWidgetConfiguration()
    intent.account = .init(account: .init(server: "Test", accountName: "Test account"))
    return intent
  }
}
