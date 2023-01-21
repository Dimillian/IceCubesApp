import Foundation

public enum Conversations: Endpoint {
  case conversations(maxId: String?)
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
    switch self {
    case let .conversations(maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    default:
      return nil
    }
  }
}
