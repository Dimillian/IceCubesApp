import AppIntents
import WidgetKit

struct LatestPostsWidgetConfiguration: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Timeline Widget Configuration"
  static let description = IntentDescription("Choose the account and timeline for this widget")

  @Parameter(title: "Account")
  var account: AppAccountEntity?

  @Parameter(title: "Timeline")
  var timeline: TimelineFilterEntity?
}

extension LatestPostsWidgetConfiguration {
  static var previewAccount: LatestPostsWidgetConfiguration {
    let intent = LatestPostsWidgetConfiguration()
    intent.account = .init(account: .init(server: "Test", accountName: "Test account"))
    intent.timeline = .init(timeline: .home)
    return intent
  }
}
