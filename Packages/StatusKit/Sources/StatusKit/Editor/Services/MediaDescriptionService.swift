import Models
import NetworkClient

extension StatusEditor {
  @MainActor
  struct MediaDescriptionService {
    struct PendingStore {
      var altTextByContainerId: [String: String] = [:]
      var mediaAttributes: [StatusData.MediaAttribute] = []
    }

    @MainActor
    protocol Client {
      func updateDescription(
        mediaId: String,
        description: String
      ) async throws -> MediaAttachment
    }

    func applyPendingAltText(
      mediaContainers: [MediaContainer],
      store: inout PendingStore
    ) {
      for container in mediaContainers {
        if let desc = store.altTextByContainerId[container.id],
          let id = container.mediaAttachment?.id
        {
          store.mediaAttributes.append(.init(id: id, description: desc, thumbnail: nil, focus: nil))
        }
      }
    }

    func addDescription(
      container: MediaContainer,
      description: String,
      client: Client
    ) async -> MediaAttachment? {
      guard case .uploaded(let attachment, _) = container.state else { return nil }
      return try? await client.updateDescription(
        mediaId: attachment.id,
        description: description
      )
    }

    func buildMediaAttribute(
      attachment: MediaAttachment,
      description: String,
      store: inout PendingStore
    ) {
      store.mediaAttributes.append(
        StatusData.MediaAttribute(
          id: attachment.id,
          description: description,
          thumbnail: nil,
          focus: nil
        )
      )
    }
  }
}

@MainActor
extension MastodonClient: StatusEditor.MediaDescriptionService.Client {
  public func updateDescription(
    mediaId: String,
    description: String
  ) async throws -> MediaAttachment {
    try await put(
      endpoint: Media.media(
        id: mediaId,
        json: .init(description: description)
      )
    )
  }
}
