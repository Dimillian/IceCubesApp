import Foundation

public enum NodeInfo: Endpoint {
  case wellKnownNodeInfo
  case nodeInfo(url: String)
  
  public func path() -> String {
    switch self {
    case .wellKnownNodeInfo:
      ".well-known/nodeinfo"
    case .nodeInfo(let url):
      // This will be a full URL, handled specially in Client
      url
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    nil
  }
  
  public var jsonValue: Encodable? {
    nil
  }
}