import Foundation

public enum Search: Endpoint {
  case search(query: String, type: String?, offset: Int?)
  
  public func path() -> String {
    switch self {
    case .search:
      return "search"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .search(query, type, offset):
      var params: [URLQueryItem] = [.init(name: "q", value: query)]
      if let type {
        params.append(.init(name: "type", value: type))
      }
      if let offset {
        params.append(.init(name: "offset", value: String(offset)))
      }
      return params
    }
  }
}
