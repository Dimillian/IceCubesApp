import Foundation

public protocol Endpoint: Sendable {
  func path() -> String
  func queryItems() -> [URLQueryItem]?
  var jsonValue: Encodable? { get }
}

public extension Endpoint {
  var jsonValue: Encodable? {
    nil
  }
}

extension Endpoint {
  func makePaginationParam(sinceId: String?, maxId: String?, mindId: String?) -> [URLQueryItem]? {
    if let sinceId {
      return [.init(name: "since_id", value: sinceId)]
    } else if let maxId {
      return [.init(name: "max_id", value: maxId)]
    } else if let mindId {
      return [.init(name: "min_id", value: mindId)]
    }
    return nil
  }
}
