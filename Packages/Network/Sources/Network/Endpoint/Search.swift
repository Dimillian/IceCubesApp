import Foundation

public enum Search: Endpoint {
  case search(query: String, type: String?, offset: Int?, following: Bool?)
  case accountsSearch(query: String, type: String?, offset: Int?, following: Bool?)

  public func path() -> String {
    switch self {
    case .search:
      "search"
    case .accountsSearch:
      "accounts/search"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .search(query, type, offset, following),
         let .accountsSearch(query, type, offset, following):
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
    }
  }
}
