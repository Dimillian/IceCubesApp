import Foundation
import Models
import NetworkClient
import UIKit

extension StatusEditor {
  struct MediaUploadService {
    protocol Client: Sendable {
      func uploadMedia(
        data: Data,
        mimeType: String,
        progressHandler: @escaping @Sendable (Double) -> Void
      ) async throws -> MediaAttachment?

      func fetchMedia(id: String) async throws -> MediaAttachment
    }

    struct UploadResult {
      var attachment: MediaAttachment
      var originalImage: UIImage?
      var needsRefresh: Bool
    }

    struct UploadPolicy: Sendable {
      var maxConcurrentUploads: Int = 2
      var retryCount: Int = 2
      var retryBackoffBase: Duration = .seconds(1)
      var retryBackoffMultiplier: Double = 2
      var maxBytes: Int? = nil
      var requiresAltText: Bool = false
    }

    struct UploadInput: Sendable {
      var id: String
      var content: MediaContainer.MediaContent
      var altText: String?
    }

    enum UploadEvent: Sendable {
      case started(id: String, content: MediaContainer.MediaContent)
      case progress(id: String, content: MediaContainer.MediaContent, progress: Double)
      case success(id: String, result: UploadResult)
      case failure(id: String, content: MediaContainer.MediaContent, error: MediaContainer.MediaError)
    }

    func upload(
      input: UploadInput,
      client: Client,
      modeIsShareExtension: Bool,
      policy: UploadPolicy,
      progressHandler: @escaping @Sendable (Double) -> Void
    ) async -> Result<UploadResult, MediaContainer.MediaError> {
      if let validationError = validate(input: input, policy: policy) {
        return .failure(validationError)
      }

      do {
        let (data, mimeType) = try await prepareUploadData(from: input.content)
        if let maxBytes = policy.maxBytes, data.count > maxBytes {
          return .failure(.sizeLimitExceeded)
        }

        return await uploadWithRetry(
          data: data,
          mimeType: mimeType,
          input: input,
          client: client,
          modeIsShareExtension: modeIsShareExtension,
          policy: policy,
          progressHandler: progressHandler
        )
      } catch let error as MediaContainer.MediaError {
        return .failure(error)
      } catch let error as ServerError {
        return .failure(.uploadFailed(error))
      } catch {
        return .failure(.compressionFailed)
      }
    }

    func uploadBatch(
      inputs: [UploadInput],
      client: Client,
      modeIsShareExtension: Bool,
      policy: UploadPolicy,
      eventHandler: @MainActor @escaping (UploadEvent) -> Void
    ) async {
      let limit = max(1, policy.maxConcurrentUploads)
      var iterator = inputs.makeIterator()

      await withTaskGroup(of: Void.self) { group in
        func addNext() {
          guard let input = iterator.next() else { return }
          group.addTask {
            await eventHandler(.started(id: input.id, content: input.content))
            let result = await self.upload(
              input: input,
              client: client,
              modeIsShareExtension: modeIsShareExtension,
              policy: policy
            ) { progress in
              Task { @MainActor in
                eventHandler(.progress(id: input.id, content: input.content, progress: progress))
              }
            }

            switch result {
            case .success(let result):
              await eventHandler(.success(id: input.id, result: result))
            case .failure(let error):
              await eventHandler(.failure(id: input.id, content: input.content, error: error))
            }
          }
        }

        for _ in 0..<limit {
          addNext()
        }

        while await group.next() != nil {
          addNext()
        }
      }
    }

    func scheduleAsyncMediaRefresh(
      attachment: MediaAttachment,
      client: Client,
      interval: Duration = .seconds(5),
      onUpdate: @MainActor @escaping (MediaAttachment) -> Void
    ) {
      Task {
        var currentAttachment = attachment
        while !Task.isCancelled {
          if currentAttachment.url != nil {
            return
          }
          do {
            let refreshed: MediaAttachment = try await client.fetchMedia(id: attachment.id)
            if refreshed.url != nil {
              await onUpdate(refreshed)
              return
            }
            currentAttachment = refreshed
          } catch {}
          try? await Task.sleep(for: interval)
        }
      }
    }

    private func validate(
      input: UploadInput,
      policy: UploadPolicy
    ) -> MediaContainer.MediaError? {
      if policy.requiresAltText {
        let trimmed = input.altText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
          return .missingAltText
        }
      }
      return nil
    }

    private func prepareUploadData(
      from content: MediaContainer.MediaContent
    ) async throws -> (Data, String) {
      let compressor = Compressor()

      switch content {
      case .image(let image):
        let data = try await compressor.compressImageForUpload(image)
        return (data, "image/jpeg")
      case .video(let transferable, _):
        let videoURL = transferable.url
        guard let compressedVideoURL = await compressor.compressVideo(videoURL),
          let videoData = try? Data(contentsOf: compressedVideoURL)
        else {
          throw MediaContainer.MediaError.compressionFailed
        }
        return (videoData, compressedVideoURL.mimeType())
      case .gif(let transferable, _):
        guard let gifData = transferable.data else {
          throw MediaContainer.MediaError.compressionFailed
        }
        return (gifData, "image/gif")
      }
    }

    private func uploadWithRetry(
      data: Data,
      mimeType: String,
      input: UploadInput,
      client: Client,
      modeIsShareExtension: Bool,
      policy: UploadPolicy,
      progressHandler: @escaping @Sendable (Double) -> Void
    ) async -> Result<UploadResult, MediaContainer.MediaError> {
      var attempt = 0
      let components = policy.retryBackoffBase.components
      var delaySeconds = Double(components.seconds)
        + Double(components.attoseconds) / 1_000_000_000_000_000_000

      while true {
        do {
          try Task.checkCancellation()
          guard let attachment = try await client.uploadMedia(
            data: data,
            mimeType: mimeType,
            progressHandler: progressHandler
          ) else {
            return .failure(.invalidFormat)
          }

          return .success(
            UploadResult(
              attachment: attachment,
              originalImage: modeIsShareExtension ? input.content.previewImage : nil,
              needsRefresh: attachment.url == nil
            )
          )
        } catch let error as MediaContainer.MediaError {
          return .failure(error)
        } catch let error as ServerError {
          if shouldRetry(error: error, attempt: attempt, policy: policy) {
            attempt += 1
            try? await Task.sleep(for: .seconds(delaySeconds))
            delaySeconds *= policy.retryBackoffMultiplier
            continue
          }
          return .failure(.uploadFailed(error))
        } catch is CancellationError {
          return .failure(.cancelled)
        } catch {
          if attempt < policy.retryCount {
            attempt += 1
            try? await Task.sleep(for: .seconds(delaySeconds))
            delaySeconds *= policy.retryBackoffMultiplier
            continue
          }
          return .failure(.compressionFailed)
        }
      }
    }

    private func shouldRetry(
      error: ServerError,
      attempt: Int,
      policy: UploadPolicy
    ) -> Bool {
      guard attempt < policy.retryCount else { return false }
      guard let httpCode = error.httpCode else { return true }
      return httpCode >= 500
    }
  }
}

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

  public func fetchMedia(id: String) async throws -> MediaAttachment {
    try await get(endpoint: Media.media(id: id, json: nil))
  }
}
