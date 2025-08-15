import AppAccount
import AppIntents
import Env
import Foundation
import Models
import NetworkClient
import UniformTypeIdentifiers

struct InlinePostImageIntent: AppIntent {
  static let title: LocalizedStringResource = "Send image(s) to Mastodon"
  static let description: IntentDescription = "Send an image or multiple images to Mastodon with Ice Cubes without opening the app"
  static let openAppWhenRun: Bool = false

  @Parameter(title: "Account", requestValueDialog: IntentDialog("Account"))
  var account: AppAccountEntity

  @Parameter(title: "Post visibility", requestValueDialog: IntentDialog("Visibility of your post"))
  var visibility: PostVisibility

  @Parameter(
    title: "Images",
    description: "Image(s) to post on Mastodon",
    supportedContentTypes: [.image, .jpeg, .png, .gif, .heic],
    inputConnectionBehavior: .connectToPreviousIntentResult)
  var images: [IntentFile]

  @Parameter(
    title: "Caption",
    requestValueDialog: IntentDialog("Caption for your post"))
  var caption: String?

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    guard !images.isEmpty else {
      return .result(dialog: "No images provided to post.")
    }

    let client = MastodonClient(
      server: account.account.server,
      version: .v1,
      oauthToken: account.account.oauthToken)

    do {
      var mediaIds: [String] = []
      for file in images {
        guard let url = file.fileURL else { continue }
        let data = try Data(contentsOf: url)
        let mimeType: String = {
          if let ut = UTType(filenameExtension: url.pathExtension), let mt = ut.preferredMIMEType {
            return mt
          } else {
            return "application/octet-stream"
          }
        }()
        let media: MediaAttachment = try await client.mediaUpload(
          endpoint: Media.medias,
          version: .v2,
          method: "POST",
          mimeType: mimeType,
          filename: url.lastPathComponent.isEmpty ? "file" : url.lastPathComponent,
          data: data)
        mediaIds.append(media.id)
      }

      let statusText = caption ?? ""
      let statusData = StatusData(
        status: statusText,
        visibility: visibility.toAppVisibility,
        mediaIds: mediaIds)
      let _: Status = try await client.post(endpoint: Statuses.postStatus(json: statusData))
      return .result(dialog: "Posted \(mediaIds.count) image(s) on Mastodon")
    } catch {
      return .result(dialog: "An error occured while posting to Mastodon, please try again.")
    }
  }
}