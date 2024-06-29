import Foundation
import Models

public enum KTagRequests: Endpoint {
  case tag(id: String)
  case follow(id: String)
  case unfollow(id: String)
  case postKtag(json: KTagData)
  case search(query: String, type: String?, offset: Int?, following: Bool?)

  public func path() -> String {
    switch self {
    case let .tag(id):
      "k_tags/\(id)/"
    case let .follow(id):
      "k_tags/\(id)/follow"
    case let .unfollow(id):
      "k_tags/\(id)/unfollow"
    case .postKtag:
      "k_tags"
    case .search:
      "k_tags"
    }
  }

    public func queryItems() -> [URLQueryItem]? {
      switch self {
      case let .search(query, type, offset, following):
        var params: [URLQueryItem] = [.init(name: "q", value: query)]
        if let type {
          params.append(.init(name: "type", value: type))
        }
        if let offset {
          params.append(.init(name: "offset", value: String(offset)))
        }
        if let following {
          params.append(.init(name: "following", value: following ? "true" : "false"))
        }
        params.append(.init(name: "resolve", value: "true"))
        return params
      default:
          return nil
      }
    }
}

protocol KTagProtocol{
    var name: String{get}
}

public struct KTagData: KTagProtocol,Encodable, Sendable {
  public let name: String

}
