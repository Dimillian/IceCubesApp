import Env
import Models
import NetworkClient

extension StatusEditor {
  @MainActor
  struct PostingService {
    @MainActor
    protocol Client {
      func postStatus(data: StatusData) async throws -> Status
      func editStatus(id: String, data: StatusData) async throws -> Status
    }

    struct Input {
      var mode: StatusEditor.EditorStore.Mode
      var statusText: String
      var visibility: Models.Visibility
      var spoilerOn: Bool
      var spoilerText: String
      var mediaAttachments: [MediaAttachment]
      var pollOptions: [String]?
      var pollVotingFrequency: PollVotingFrequency
      var pollDuration: Duration
      var selectedLanguage: String?
      var pendingMediaAttributes: [StatusData.MediaAttribute]
      var embeddedStatusId: String?
      var allMediaHasDescription: Bool
      var requiresAltText: Bool
    }

    func buildStatusData(from input: Input) throws -> StatusData {
      if input.requiresAltText, !input.allMediaHasDescription {
        throw PostError.missingAltText
      }

      var pollData: StatusData.PollData?
      if let pollOptions = input.pollOptions {
        pollData = .init(
          options: pollOptions,
          multiple: input.pollVotingFrequency.canVoteMultipleTimes,
          expires_in: input.pollDuration.rawValue
        )
      }

      return StatusData(
        status: input.statusText,
        visibility: input.visibility,
        inReplyToId: input.mode.replyToStatus?.id,
        spoilerText: input.spoilerOn ? input.spoilerText : nil,
        mediaIds: input.mediaAttachments.map(\.id),
        poll: pollData,
        language: input.selectedLanguage,
        mediaAttributes: input.pendingMediaAttributes,
        quotedStatusId: input.embeddedStatusId
      )
    }

    func submit(
      input: Input,
      client: Client
    ) async throws -> Status {
      let data = try buildStatusData(from: input)
      switch input.mode {
      case .new, .replyTo, .quote, .mention, .shareExtension, .quoteLink, .imageURL:
        let status = try await client.postStatus(data: data)
        StreamWatcher.shared.emmitPostEvent(for: status)
        return status
      case .edit(let status):
        let updated = try await client.editStatus(id: status.id, data: data)
        StreamWatcher.shared.emmitEditEvent(for: updated)
        return updated
      }
    }
  }
}

@MainActor
extension MastodonClient: StatusEditor.PostingService.Client {
  public func postStatus(data: StatusData) async throws -> Status {
    try await post(endpoint: Statuses.postStatus(json: data))
  }

  public func editStatus(id: String, data: StatusData) async throws -> Status {
    try await put(endpoint: Statuses.editStatus(id: id, json: data))
  }
}
