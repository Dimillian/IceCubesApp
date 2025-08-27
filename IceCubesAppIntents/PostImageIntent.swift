import AppIntents
import Foundation

struct PostImageIntent: AppIntent {
  static let title: LocalizedStringResource = "Post an image to Mastodon"
  static let description: IntentDescription =
    "Use Ice Cubes to compose a post with an image to Mastodon"
  static let openAppWhenRun: Bool = true

  @Parameter(
    title: "Image",
    description: "Image to post on Mastodon",
    supportedContentTypes: [.image, .jpeg, .png, .gif, .heic],
    inputConnectionBehavior: .connectToPreviousIntentResult)
  var images: [IntentFile]?

  @Parameter(
    title: "Caption",
    requestValueDialog: IntentDialog("Caption for your post"))
  var caption: String?

  @Parameter(
    title: "Image description",
    requestValueDialog: IntentDialog("ALT text for the image"))
  var altText: String?

  func perform() async throws -> some IntentResult {
    AppIntentService.shared.handledIntent = .init(intent: self)
    return .result()
  }
}
