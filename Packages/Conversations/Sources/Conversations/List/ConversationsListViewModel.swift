import Models
import Network
import SwiftUI

@MainActor
class ConversationsListViewModel: ObservableObject {
  var client: Client?
  
  @Published var isLoadingFirstPage: Bool = true
  @Published var conversations: [Conversation] = []
  @Published var isError: Bool = false
  
  public init() { }
  
  func fetchConversations() async {
    guard let client else { return }
    if conversations.isEmpty {
      isLoadingFirstPage = true
    }
    do {
      conversations = try await client.get(endpoint: Conversations.conversations)
      isLoadingFirstPage = false
    } catch {
      isError = true
      isLoadingFirstPage = false
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
  
  func handleEvent(event: any StreamEvent) {
    if let event = event as? StreamEventConversation {
      if let index = conversations.firstIndex(where: { $0.id == event.conversation.id }) {
        conversations.remove(at: index)
      }
      conversations.insert(event.conversation, at: 0)
      conversations = conversations.sorted(by: { $0.lastStatus.createdAt.asDate > $1.lastStatus.createdAt.asDate })
    }
  }
}
