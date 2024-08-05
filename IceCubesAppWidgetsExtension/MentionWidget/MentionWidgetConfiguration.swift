import AppIntents
import WidgetKit

struct MentionsWidgetConfiguration: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Mentions Widget Configuration"
  static let description = IntentDescription("Choose the account for this widget")

  @Parameter(title: "Account")
  var account: AppAccountEntity?
}

extension MentionsWidgetConfiguration {
  static var previewAccount: MentionsWidgetConfiguration {
    let intent = MentionsWidgetConfiguration()
    intent.account = .init(account: .init(server: "Test", accountName: "Test account"))
    return intent
  }
}
