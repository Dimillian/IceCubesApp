import Foundation

public protocol Endpoint: Sendable {
  func path() -> String
  func queryItems() -> [URLQueryItem]?
  var jsonValue: Encodable? { get }
}

extension Endpoint {
  public var jsonValue: Encodable? {
    nil
  }
}

extension Endpoint {
  func makePaginationParam(sinceId: String?, maxId: String?, mindId: String?) -> [URLQueryItem]? {
    var params: [URLQueryItem] = []

    if let sinceId {
      params.append(.init(name: "since_id", value: sinceId))
    }
    if let maxId {
      params.append(.init(name: "max_id", value: maxId))
    }
    if let mindId {
      params.append(.init(name: "min_id", value: mindId))
    }

    return params.isEmpty ? nil : params
  }
}
