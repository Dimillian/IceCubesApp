import AppIntents
import WidgetKit

struct AccountWidgetConfiguration: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Configuration"
  static let description = IntentDescription("Choose the account for this widget")

  @Parameter(title: "Account")
  var account: AppAccountEntity
}

extension AccountWidgetConfiguration {
  static var previewAccount: AccountWidgetConfiguration {
    let intent = AccountWidgetConfiguration()
    intent.account = .init(account: .init(server: "Test", accountName: "Test account"))
    return intent
  }
}
