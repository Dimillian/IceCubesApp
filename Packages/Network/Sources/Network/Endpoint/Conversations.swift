import Foundation

public enum Conversations: Endpoint {
  case conversations(maxId: String?)
  case delete(id: String)
  case read(id: String)

  public func path() -> String {
    switch self {
    case .conversations:
      "conversations"
    case let .delete(id):
      "conversations/\(id)"
    case let .read(id):
      "conversations/\(id)/read"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .conversations(maxId):
      makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    default:
      nil
    }
  }
}
