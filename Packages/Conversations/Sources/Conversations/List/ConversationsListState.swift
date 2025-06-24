import Foundation
import Models
import Network

public enum ConversationsListState {
  case loading
  case display(conversations: [Conversation], hasNextPage: Bool)
  case error(error: Error)
}