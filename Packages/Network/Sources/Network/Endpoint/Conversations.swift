import Foundation

public enum Conversations: Endpoint {
  case conversations
  case delete(id: String)
  case read(id: String)

  public func path() -> String {
    switch self {
    case .conversations:
      return "conversations"
    case let .delete(id):
      return "conversations/\(id)"
    case let .read(id):
      return "conversations/\(id)/read"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    return nil
  }
}
