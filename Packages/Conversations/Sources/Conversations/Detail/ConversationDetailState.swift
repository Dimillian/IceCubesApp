import Foundation
import Models

public enum ConversationDetailState {
  case loading
  case display(messages: [Status], conversation: Conversation)
  case error(error: Error)
}