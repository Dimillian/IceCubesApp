import Foundation
import Models
import NetworkClient

@MainActor
public final class ConversationsListDataSource {
  // Internal state
  private var conversations: [Conversation] = []
  private var nextPage: LinkHandler?
  
  public init() {}
  
  // MARK: - Public Methods
  
  public func reset() {
    conversations = []
    nextPage = nil
  }
  
  public struct FetchResult {
    let conversations: [Conversation]
    let hasNextPage: Bool
  }
  
  public func fetchConversations(client: MastodonClient) async throws -> FetchResult {
    let (newConversations, newNextPage): ([Conversation], LinkHandler?) = try await client.getWithLink(
      endpoint: Conversations.conversations(maxId: nil)
    )
    
    conversations = newConversations
    nextPage = newNextPage
    
    // Check if nextPage is actually valid
    if nextPage?.maxId == nil {
      nextPage = nil
    }
    
    return FetchResult(
      conversations: conversations,
      hasNextPage: nextPage != nil
    )
  }
  
  public func fetchNextPage(client: MastodonClient) async throws -> FetchResult {
    guard let maxId = nextPage?.maxId else {
      return FetchResult(conversations: conversations, hasNextPage: false)
    }
    
    let (nextConversations, newNextPage): ([Conversation], LinkHandler?) = try await client.getWithLink(
      endpoint: Conversations.conversations(maxId: maxId)
    )
    
    conversations.append(contentsOf: nextConversations)
    nextPage = newNextPage
    
    // Check if nextPage is actually valid
    if nextPage?.maxId == nil {
      nextPage = nil
    }
    
    return FetchResult(
      conversations: conversations,
      hasNextPage: nextPage != nil
    )
  }
  
  public func markAsRead(client: MastodonClient, conversation: Conversation) async -> Conversation {
    _ = try? await client.post(endpoint: Conversations.read(id: conversation.id))
    
    // Update the conversation in our local state
    let updatedConversation = Conversation(
      id: conversation.id,
      unread: false,
      lastStatus: conversation.lastStatus,
      accounts: conversation.accounts
    )
    
    if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
      conversations[index] = updatedConversation
    }
    
    return updatedConversation
  }
  
  public func delete(client: MastodonClient, conversation: Conversation) async throws -> [Conversation] {
    _ = try? await client.delete(endpoint: Conversations.delete(id: conversation.id))
    
    // Remove from local state
    conversations.removeAll { $0.id == conversation.id }
    
    return conversations
  }
  
  public func toggleFavorite(client: MastodonClient, conversation: Conversation) async throws -> Conversation {
    guard let message = conversation.lastStatus else { return conversation }
    
    let endpoint: Endpoint = if message.favourited ?? false {
      Statuses.unfavorite(id: message.id)
    } else {
      Statuses.favorite(id: message.id)
    }
    
    let updatedStatus: Status = try await client.post(endpoint: endpoint)
    let updatedConversation = updateConversationWithNewLastStatus(
      conversation: conversation,
      newLastStatus: updatedStatus
    )
    
    return updatedConversation
  }
  
  public func toggleBookmark(client: MastodonClient, conversation: Conversation) async throws -> Conversation {
    guard let message = conversation.lastStatus else { return conversation }
    
    let endpoint: Endpoint = if message.bookmarked ?? false {
      Statuses.unbookmark(id: message.id)
    } else {
      Statuses.bookmark(id: message.id)
    }
    
    let updatedStatus: Status = try await client.post(endpoint: endpoint)
    let updatedConversation = updateConversationWithNewLastStatus(
      conversation: conversation,
      newLastStatus: updatedStatus
    )
    
    return updatedConversation
  }
  
  public func handleStreamEvent(event: any StreamEvent) -> [Conversation]? {
    guard let event = event as? StreamEventConversation else { return nil }
    
    updateConversations(conversation: event.conversation)
    return conversations
  }
  
  // MARK: - Private Methods
  
  private func updateConversationWithNewLastStatus(
    conversation: Conversation,
    newLastStatus: Status
  ) -> Conversation {
    let newConversation = Conversation(
      id: conversation.id,
      unread: conversation.unread,
      lastStatus: newLastStatus,
      accounts: conversation.accounts
    )
    updateConversations(conversation: newConversation)
    return newConversation
  }
  
  private func updateConversations(conversation: Conversation) {
    // Remove existing conversation if present
    if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
      conversations.remove(at: index)
    }
    
    // Insert at the beginning
    conversations.insert(conversation, at: 0)
    
    // Sort by last status date
    conversations = conversations.sorted { conv1, conv2 in
      let date1 = conv1.lastStatus?.createdAt.asDate ?? Date.now
      let date2 = conv2.lastStatus?.createdAt.asDate ?? Date.now
      return date1 > date2
    }
  }
}
