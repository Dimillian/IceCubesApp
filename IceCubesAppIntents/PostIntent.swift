import AppIntents
import Foundation

struct PostIntent: AppIntent {
  static let title: LocalizedStringResource = "Compose a post to Mastodon"
  static let description: IntentDescription = "Use Ice Cubes to compose a post for Mastodon"
  static let openAppWhenRun: Bool = true

  @Parameter(title: "Post content", inputConnectionBehavior: .connectToPreviousIntentResult)
  var content: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Compose \(\.$content)")
  }

  func perform() async throws -> some IntentResult {
    AppIntentService.shared.handledIntent = .init(intent: self)
    return .result()
  }
}
