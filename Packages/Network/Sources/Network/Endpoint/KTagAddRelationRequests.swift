import Foundation

public enum KTagAddRelationRequests: Endpoint {
  case show(id: String)
  case create(json: KTagAddRelatioonRequestData)
  case list
  case approve(id:String)
  case deny(id:String)
    case delete(id:String)

  public func path() -> String {
    switch self {
    case let .show(id):
      "k_tag_add_relation_requests/\(id)/"
    case .create://post
      "k_tag_add_relation_requests"
    case let .approve(id): //post
      "k_tag_add_relation_requests/\(id)/approve"
    case let .deny(id)://post
      "k_tag_add_relation_requests/\(id)/deny"
    case let .delete(id):
        "k_tag_add_relation_requests/\(id)/"
    case .list:
        "k_tag_add_relation_requests"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    default:
      nil
    }
  }
    public var jsonValue: Encodable? {
      switch self {
      case let .create(json):
        json
      default:
        nil
      }
    }
}
// 自分のユーザーIDは認証情報で渡してるからいらない。
public struct KTagAddRelatioonRequestData: Encodable, Sendable {
  public let k_tag_id: String
    public let status_id: String
    public init(k_tag_id: String,status_id: String){
        self.k_tag_id = k_tag_id
        self.status_id = status_id
    }
}
