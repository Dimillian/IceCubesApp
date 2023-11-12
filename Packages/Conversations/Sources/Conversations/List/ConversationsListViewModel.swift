import Models
import Network
import SwiftUI

@MainActor
@Observable class ConversationsListViewModel {
  var client: Client?

  var isLoadingFirstPage: Bool = true
  var isLoadingNextPage: Bool = false
  var conversations: [Conversation] = []
  var isError: Bool = false

  var nextPage: LinkHandler?

  var scrollToTopVisible: Bool = false

  public init() {}

  func fetchConversations() async {
    guard let client else { return }
    if conversations.isEmpty {
      isLoadingFirstPage = true
    }
    do {
      (conversations, nextPage) = try await client.getWithLink(endpoint: Conversations.conversations(maxId: nil))
      if nextPage?.maxId == nil {
        nextPage = nil
      }
      isLoadingFirstPage = false
    } catch {
      isError = true
      isLoadingFirstPage = false
    }
  }

  func fetchNextPage() async {
    if let maxId = nextPage?.maxId, let client {
      do {
        isLoadingNextPage = true
        var nextMessages: [Conversation] = []
        (nextMessages, nextPage) = try await client.getWithLink(endpoint: Conversations.conversations(maxId: maxId))
        conversations.append(contentsOf: nextMessages)
        if nextPage?.maxId == nil {
          nextPage = nil
        }
        isLoadingNextPage = false
      } catch {}
    }
  }

  func markAsRead(conversation: Conversation) async {
    guard let client else { return }
    _ = try? await client.post(endpoint: Conversations.read(id: conversation.id))
  }

  func delete(conversation: Conversation) async {
    guard let client else { return }
    _ = try? await client.delete(endpoint: Conversations.delete(id: conversation.id))
    await fetchConversations()
  }

  func favorite(conversation: Conversation) async {
    guard let client, let message = conversation.lastStatus else { return }
    let endpoint: Endpoint = if message.favourited ?? false {
      Statuses.unfavorite(id: message.id)
    } else {
      Statuses.favorite(id: message.id)
    }
    do {
      let status: Status = try await client.post(endpoint: endpoint)
      updateConversationWithNewLastStatus(conversation: conversation, newLastStatus: status)
    } catch {}
  }

  func bookmark(conversation: Conversation) async {
    guard let client, let message = conversation.lastStatus else { return }
    let endpoint: Endpoint = if message.bookmarked ?? false {
      Statuses.unbookmark(id: message.id)
    } else {
      Statuses.bookmark(id: message.id)
    }
    do {
      let status: Status = try await client.post(endpoint: endpoint)
      updateConversationWithNewLastStatus(conversation: conversation, newLastStatus: status)
    } catch {}
  }

  private func updateConversationWithNewLastStatus(conversation: Conversation, newLastStatus: Status) {
    let newConversation = Conversation(id: conversation.id, unread: conversation.unread, lastStatus: newLastStatus, accounts: conversation.accounts)
    updateConversations(conversation: newConversation)
  }

  private func updateConversations(conversation: Conversation) {
    if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
      conversations.remove(at: index)
    }
    conversations.insert(conversation, at: 0)
    conversations = conversations.sorted(by: { ($0.lastStatus?.createdAt.asDate ?? Date.now) > ($1.lastStatus?.createdAt.asDate ?? Date.now) })
  }

  func handleEvent(event: any StreamEvent) {
    if let event = event as? StreamEventConversation {
      updateConversations(conversation: event.conversation)
    }
  }
}
