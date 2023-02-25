import Models
import Network
import SwiftUI

@MainActor
class ConversationsListRowModel: ObservableObject, Identifiable {
    @Published var conversation: Conversation {
        didSet{
          setValues()
        }
    }
    @Published var isLiked: Bool = false
    @Published var isBookmarked: Bool = false
    var client: Client?
    var superViewModel: ConversationsListViewModel
    
    var id: String {
        conversation.id
    }
    
    init(conversation: Conversation, client: Client?, superViewModel: ConversationsListViewModel) {
        self.conversation = conversation
        self.client = client
        self.superViewModel = superViewModel
        setValues()
    }
    
    private func setValues() {
        if let message = conversation.lastStatus {
            isLiked = message.favourited ?? false
            isBookmarked = message.bookmarked ?? false
        } else {
            isLiked = false
            isBookmarked = false
        }
    }

    func markAsRead() async {
      guard let client else { return }
      _ = try? await client.post(endpoint: Conversations.read(id: conversation.id))
    }

    func delete() async {
      guard let client else { return }
      _ = try? await client.delete(endpoint: Conversations.delete(id: conversation.id))
        await superViewModel.fetchConversations()
    }

    func favorite() async {
        guard let client, let message = conversation.lastStatus else { return }
        let endpoint: Endpoint
        if isLiked ?? false {
          endpoint = Statuses.unfavorite(id: message.id)
        } else {
            endpoint = Statuses.favorite(id: message.id)
        }
        do {
            let status: Status = try await client.post(endpoint: endpoint)
            conversation.lastStatus = status
        } catch {}
    }
      
    func bookmark() async {
        guard let client, let message = conversation.lastStatus else { return }
        let endpoint: Endpoint
        if isBookmarked ?? false {
          endpoint = Statuses.unbookmark(id: message.id)
        } else {
            endpoint = Statuses.bookmark(id: message.id)
        }
        do {
            let status: Status = try await client.post(endpoint: endpoint)
            conversation.lastStatus = status
        } catch {}
    }
}
