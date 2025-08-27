import AppAccount
import AppIntents
import Env
import Foundation
import Models
import NetworkClient
import UniformTypeIdentifiers
import CoreGraphics
import ImageIO

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

  @Parameter(
    title: "Image descriptions",
    requestValueDialog: IntentDialog("Descriptions (ALT) for your images in order"))
  var altTexts: [String]?

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
      var attributes: [StatusData.MediaAttribute] = []
      for (index, file) in images.enumerated() {
        guard let url = file.fileURL else { continue }
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        let data: Data
        let contentType: String
        if let converted = makeJPEGData(from: url) {
          data = converted.0
          contentType = converted.1
        } else {
          data = try Data(contentsOf: url)
          contentType = mimeType(for: url)
        }
        let media: MediaAttachment = try await client.mediaUpload(
          endpoint: Media.medias,
          version: .v2,
          method: "POST",
          mimeType: contentType,
          filename: "file",
          data: data)

        if let altTexts, index < altTexts.count {
          let desc = altTexts[index].trimmingCharacters(in: .whitespacesAndNewlines)
          if !desc.isEmpty {
            // Best-effort: update media description immediately
            _ = try? await client.put(
              endpoint: Media.media(
                id: media.id,
                json: .init(description: desc))) as MediaAttachment
            // Also include description in the status post as a fallback
            attributes.append(.init(id: media.id, description: desc, thumbnail: nil, focus: nil))
          }
        }

        mediaIds.append(media.id)
      }

      let statusText = caption ?? ""
      let statusData = StatusData(
        status: statusText,
        visibility: visibility.toAppVisibility,
        mediaIds: mediaIds,
        mediaAttributes: attributes.isEmpty ? nil : attributes)
      let _: Status = try await client.post(endpoint: Statuses.postStatus(json: statusData))
      return .result(dialog: "Posted \(mediaIds.count) image(s) on Mastodon")
    } catch {
      return .result(dialog: "Error: \(error.localizedDescription)")
    }
  }

  private func mimeType(for url: URL) -> String {
    if let ut = UTType(filenameExtension: url.pathExtension), let mt = ut.preferredMIMEType {
      return mt
    }
    return "application/octet-stream"
  }

  private func makeJPEGData(from url: URL) -> (Data, String)? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
      return nil
    }

    let maxPixelSize: Int = 1536
    let downsampleOptions = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ] as [CFString: Any] as CFDictionary

    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
      return nil
    }

    let data = NSMutableData()
    guard let imageDestination = CGImageDestinationCreateWithData(
      data, UTType.jpeg.identifier as CFString, 1, nil)
    else {
      return nil
    }

    let destinationProperties = [
      kCGImageDestinationLossyCompressionQuality: 0.8
    ] as CFDictionary

    CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
    CGImageDestinationFinalize(imageDestination)

    return (data as Data, "image/jpeg")
  }
}