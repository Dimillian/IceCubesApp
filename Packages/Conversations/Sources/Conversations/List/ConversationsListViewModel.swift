import Models
import Network
import SwiftUI

@MainActor
class ConversationsListViewModel: ObservableObject {
  var client: Client?

  @Published var isLoadingFirstPage: Bool = true
  @Published var isLoadingNextPage: Bool = false
  @Published var conversations: [ConversationsListRowModel] = []
  @Published var isError: Bool = false

  var nextPage: LinkHandler?

  public init() {}

  func fetchConversations() async {
      let conversationObjects: [Conversation]
    guard let client else { return }
    if conversations.isEmpty {
      isLoadingFirstPage = true
    }
    do {
      (conversationObjects, nextPage) = try await client.getWithLink(endpoint: Conversations.conversations(maxId: nil))
        updateChildModels(conversationObjects: conversationObjects)
        if nextPage?.maxId == nil {
        nextPage = nil
      }
      isLoadingFirstPage = false
    } catch {
      isError = true
      isLoadingFirstPage = false
    }
  }

  private func updateChildModels(conversationObjects:  [Conversation]) {
    var objs = conversationObjects
    var modelsToDelete: [Int] = []
    
    for (modelIndex, model) in conversations.enumerated() {
      if let index = objs.firstIndex(where: { $0.id == model.conversation.id }) {
        model.conversation = objs[index]
        objs.remove(at: index)
      } else {
        modelsToDelete.append(modelIndex)
      }
    }
    
    for index in modelsToDelete {
      conversations.remove(at: index)
    }
    
    conversations.append(contentsOf: objs.map {
      ConversationsListRowModel(conversation: $0, client: client, superViewModel: self)
    })
  }
  
  func fetchNextPage() async {
    if let maxId = nextPage?.maxId, let client {
      do {
        isLoadingNextPage = true
        var nextMessages: [Conversation] = []
        (nextMessages, nextPage) = try await client.getWithLink(endpoint: Conversations.conversations(maxId: maxId))
          conversations.append(contentsOf: nextMessages.map { obj in
              ConversationsListRowModel(conversation: obj, client: client, superViewModel: self)
          })
        if nextPage?.maxId == nil {
          nextPage = nil
        }
        isLoadingNextPage = false
      } catch {}
    }
  }

  func handleEvent(event: any StreamEvent) {
    if let event = event as? StreamEventConversation {
      if let index = conversations.firstIndex(where: { $0.conversation.id == event.conversation.id }) {
        conversations[index].conversation = event.conversation
      } else {
        let conversation = ConversationsListRowModel(conversation: event.conversation, client: client, superViewModel: self)
        conversations.insert(conversation, at: 0)
      }
      conversations = conversations.sorted(by: { ($0.conversation.lastStatus?.createdAt.asDate ?? Date.now) > ($1.conversation.lastStatus?.createdAt.asDate ?? Date.now) })
    }
  }
}
