import Foundation
import Models
import Network
import SwiftUI

@MainActor
@Observable class ConversationDetailViewModel {
  var client: Client?

  var conversation: Conversation

  var isLoadingMessages: Bool = true
  var messages: [Status] = []

  var isSendingMessage: Bool = false
  var newMessageText: String = ""

  init(conversation: Conversation) {
    self.conversation = conversation
    messages = conversation.lastStatus != nil ? [conversation.lastStatus!] : []
  }

  func fetchMessages() async {
    guard let client, let lastMessageId = messages.last?.id else { return }
    do {
      let context: StatusContext = try await client.get(endpoint: Statuses.context(id: lastMessageId))
      isLoadingMessages = false
      messages.insert(contentsOf: context.ancestors, at: 0)
      messages.append(contentsOf: context.descendants)
    } catch {}
  }

  func postMessage() async {
    guard let client else { return }
    isSendingMessage = true
    var finalText = conversation.accounts.map { "@\($0.acct)" }.joined(separator: " ")
    finalText += " "
    finalText += newMessageText
    let data = StatusData(status: finalText,
                          visibility: .direct,
                          inReplyToId: messages.last?.id)
    do {
      let status: Status = try await client.post(endpoint: Statuses.postStatus(json: data))
      appendNewStatus(status: status)
      withAnimation {
        newMessageText = ""
        isSendingMessage = false
      }
    } catch {
      isSendingMessage = false
    }
  }

  func handleEvent(event: any StreamEvent) {
    if let event = event as? StreamEventStatusUpdate,
       let index = messages.firstIndex(where: { $0.id == event.status.id })
    {
      messages[index] = event.status
    } else if let event = event as? StreamEventDelete,
              let index = messages.firstIndex(where: { $0.id == event.status })
    {
      messages.remove(at: index)
    } else if let event = event as? StreamEventConversation,
              event.conversation.id == conversation.id
    {
      conversation = event.conversation
      if conversation.lastStatus != nil {
        appendNewStatus(status: conversation.lastStatus!)
      }
    }
  }

  private func appendNewStatus(status: Status) {
    if !messages.contains(where: { $0.id == status.id }) {
      messages.append(status)
    }
  }
}
