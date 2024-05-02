import Foundation
import AppIntents

struct PostIntent: AppIntent {
  static let title: LocalizedStringResource = "Post to Mastodon"
  static var description: IntentDescription {
    get {
      "Use Ice Cubes to post text to Mastodon"
    }
  }
  static let openAppWhenRun: Bool = true
  
  @Parameter(title: "Post content")
  var content: String?
  
  func perform() async throws -> some IntentResult {
    AppIntentService.shared.handledIntent = .init(intent: self)
    return .result()
  }
}
