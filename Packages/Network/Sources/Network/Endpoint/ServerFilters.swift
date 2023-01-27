import Foundation
import Models

public enum ServerFilters: Endpoint {
  case filters
  case createFilter(json: ServerFilterData)
  case editFilter(id: String, json: ServerFilterData)
  case addKeyword(filter: String, keyword: String, wholeWord: Bool)
  case removeKeyword(id: String)
  case filter(id: String)

  public func path() -> String {
    switch self {
    case .filters:
      return "filters"
    case .createFilter:
      return "filters"
    case let .filter(id):
      return "filters/\(id)"
    case let .editFilter(id, _):
      return "filters/\(id)"
    case let .addKeyword(id, _, _):
      return "filters/\(id)/keywords"
    case let .removeKeyword(id):
      return "filters/keywords/\(id)"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .addKeyword(_, keyword, wholeWord):
      return [.init(name: "keyword", value: keyword),
              .init(name: "whole_word", value: wholeWord ? "true" : "false")]
    default:
      return nil
    }
  }

  public var jsonValue: Encodable? {
    switch self {
    case let .createFilter(json):
      return json
    case let .editFilter(_, json):
      return json
    default:
      return nil
    }
  }
}

public struct ServerFilterData: Encodable {
  public let title: String
  public let context: [ServerFilter.Context]
  public let filterAction: ServerFilter.Action
  public let expireIn: Int?

  public init(title: String,
              context: [ServerFilter.Context],
              filterAction: ServerFilter.Action,
              expireIn: Int?)
  {
    self.title = title
    self.context = context
    self.filterAction = filterAction
    self.expireIn = expireIn
  }
}
