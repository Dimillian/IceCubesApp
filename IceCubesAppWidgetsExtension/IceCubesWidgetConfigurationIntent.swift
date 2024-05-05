import WidgetKit
import AppIntents

struct IceCubesWidgetConfigurationIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Configuration"
  static let description = IntentDescription("Choose the account and timeline for this widget")
  
  @Parameter(title: "Account")
  var account: AppAccountEntity?
  
  @Parameter(title: "Timeline")
  var timeline: TimelineFilterEntity?
}

extension IceCubesWidgetConfigurationIntent {
  static var previewAccount: IceCubesWidgetConfigurationIntent {
    let intent = IceCubesWidgetConfigurationIntent()
    intent.account = .init(account: .init(server: "Test", accountName: "Test account"))
    intent.timeline = .init(timeline: .home)
    return intent
  }
}
