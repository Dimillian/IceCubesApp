import Foundation
import AppIntents

struct PostImageIntent: AppIntent {
  static let title: LocalizedStringResource = "Post an image to Mastodon"
  static var description: IntentDescription {
    get {
      "Use Ice Cubes to post a status with an image to Mastodon"
    }
  }
  static let openAppWhenRun: Bool = true
  
  @Parameter(title: "Image",
             description: "Image to post on Mastodon",
             supportedTypeIdentifiers: ["public.image"],
             inputConnectionBehavior: .connectToPreviousIntentResult)
  var images: [IntentFile]?
  
  func perform() async throws -> some IntentResult {
    AppIntentService.shared.handledIntent = .init(intent: self)
    return .result()
  }
}
