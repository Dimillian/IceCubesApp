import Foundation
import Models
import NetworkClient

@MainActor
public final class ConversationDetailDataSource {
  // Internal state
  private var messages: [Status] = []
  private var conversation: Conversation

  public init(conversation: Conversation) {
    self.conversation = conversation
    // Initialize with last status if available
    if let lastStatus = conversation.lastStatus {
      messages = [lastStatus]
    }
  }

  public struct FetchResult {
    let messages: [Status]
    let conversation: Conversation
  }

  public func fetchMessages(client: MastodonClient) async throws -> FetchResult {
    guard let lastMessageId = messages.last?.id else {
      return FetchResult(messages: messages, conversation: conversation)
    }

    let context: StatusContext = try await client.get(
      endpoint: Statuses.context(id: lastMessageId)
    )

    // Build the complete message list
    var allMessages: [Status] = []
    allMessages.append(contentsOf: context.ancestors)

    // Add existing messages (avoiding duplicates)
    for message in messages {
      if !allMessages.contains(where: { $0.id == message.id }) {
        allMessages.append(message)
      }
    }

    // Add descendants
    allMessages.append(contentsOf: context.descendants)

    messages = allMessages

    return FetchResult(messages: messages, conversation: conversation)
  }

  public struct PostMessageResult {
    let messages: [Status]
    let conversation: Conversation
    let success: Bool
  }

  public func postMessage(
    client: MastodonClient,
    messageText: String
  ) async throws -> PostMessageResult {
    var finalText = conversation.accounts.map { "@\($0.acct)" }.joined(separator: " ")
    finalText += " "
    finalText += messageText

    let data = StatusData(
      status: finalText,
      visibility: .direct,
      inReplyToId: messages.last?.id
    )

    let status: Status = try await client.post(endpoint: Statuses.postStatus(json: data))
    appendNewStatus(status: status)

    return PostMessageResult(
      messages: messages,
      conversation: conversation,
      success: true
    )
  }

  public struct StreamEventResult {
    let messages: [Status]
    let conversation: Conversation
  }

  public func handleStreamEvent(event: any StreamEvent) -> StreamEventResult? {
    var hasChanges = false

    if let event = event as? StreamEventStatusUpdate,
      let index = messages.firstIndex(where: { $0.id == event.status.id })
    {
      messages[index] = event.status
      hasChanges = true
    } else if let event = event as? StreamEventDelete,
      let index = messages.firstIndex(where: { $0.id == event.status })
    {
      messages.remove(at: index)
      hasChanges = true
    } else if let event = event as? StreamEventConversation,
      event.conversation.id == conversation.id
    {
      conversation = event.conversation
      if let lastStatus = conversation.lastStatus {
        appendNewStatus(status: lastStatus)
      }
      hasChanges = true
    }

    guard hasChanges else { return nil }

    return StreamEventResult(
      messages: messages,
      conversation: conversation
    )
  }

  // MARK: - Private Methods

  private func appendNewStatus(status: Status) {
    if !messages.contains(where: { $0.id == status.id }) {
      messages.append(status)
    }
  }
}
