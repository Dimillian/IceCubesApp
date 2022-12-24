import Foundation

public protocol Endpoint {
  func path() -> String
  func queryItems() -> [URLQueryItem]?
}

extension Endpoint {
  func makePaginationParam(sinceId: String?, maxId: String?) -> [URLQueryItem]? {
    if let sinceId {
      return [.init(name: "since_id", value: sinceId)]
    } else if let maxId {
      return [.init(name: "max_id", value: maxId)]
    }
    return nil
  }
}
