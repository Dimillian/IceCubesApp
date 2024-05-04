import AppIntents
import Foundation

struct PostIntent: AppIntent {
  static let title: LocalizedStringResource = "Post status to Mastodon"
  static var description: IntentDescription {
    "Use Ice Cubes to post a status to Mastodon"
  }

  static let openAppWhenRun: Bool = true

  @Parameter(title: "Post content", inputConnectionBehavior: .connectToPreviousIntentResult)
  var content: String?

  func perform() async throws -> some IntentResult {
    AppIntentService.shared.handledIntent = .init(intent: self)
    return .result()
  }
}
