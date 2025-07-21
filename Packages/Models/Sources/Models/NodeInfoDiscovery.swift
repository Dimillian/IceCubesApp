import Foundation

public struct NodeInfoDiscovery: Codable, Sendable {
  public struct Link: Codable, Sendable {
    public let rel: String
    public let href: String
  }
  
  public let links: [Link]
  
  public var nodeInfo20URL: String? {
    return links.first { $0.rel == "http://nodeinfo.diaspora.software/ns/schema/2.0" }?.href
  }
}