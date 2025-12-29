import Foundation
import Models
import NetworkClient
import UIKit

extension StatusEditor {
  @MainActor
  struct MediaUploadService {
    @MainActor
    protocol Client {
      func uploadMedia(
        data: Data,
        mimeType: String,
        progressHandler: @escaping @Sendable (Double) -> Void
      ) async throws -> MediaAttachment?
    }

    struct UploadResult {
      var attachment: MediaAttachment
      var originalImage: UIImage?
      var needsRefresh: Bool
    }

    func upload(
      content: MediaContainer.MediaContent,
      client: Client,
      modeIsShareExtension: Bool,
      progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> UploadResult? {
      let compressor = Compressor()
      let data: Data
      let mimeType: String

      switch content {
      case .image(let image):
        data = try await compressor.compressImageForUpload(image)
        mimeType = "image/jpeg"
      case .video(let transferable, _):
        let videoURL = transferable.url
        guard let compressedVideoURL = await compressor.compressVideo(videoURL),
          let videoData = try? Data(contentsOf: compressedVideoURL)
        else {
          throw MediaContainer.MediaError.compressionFailed
        }
        data = videoData
        mimeType = compressedVideoURL.mimeType()
      case .gif(let transferable, _):
        guard let gifData = transferable.data else {
          throw MediaContainer.MediaError.compressionFailed
        }
        data = gifData
        mimeType = "image/gif"
      }

      guard let attachment = try await client.uploadMedia(
        data: data,
        mimeType: mimeType,
        progressHandler: progressHandler
      ) else {
        return nil
      }

      return UploadResult(
        attachment: attachment,
        originalImage: modeIsShareExtension ? content.previewImage : nil,
        needsRefresh: attachment.url == nil
      )
    }
  }
}

@MainActor
extension MastodonClient: StatusEditor.MediaUploadService.Client {
  public func uploadMedia(
    data: Data,
    mimeType: String,
    progressHandler: @escaping @Sendable (Double) -> Void
  ) async throws -> MediaAttachment? {
    try await mediaUpload(
      endpoint: Media.medias,
      version: .v2,
      method: "POST",
      mimeType: mimeType,
      filename: "file",
      data: data,
      progressHandler: progressHandler
    )
  }
}
