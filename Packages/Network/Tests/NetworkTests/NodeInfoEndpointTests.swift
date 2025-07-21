import Testing
import Foundation
@testable import Network

@Suite("NodeInfo Endpoint Tests")
struct NodeInfoEndpointTests {
  
  @Test("NodeInfo wellKnownNodeInfo endpoint path")
  func testWellKnownNodeInfoPath() {
    let endpoint = NodeInfo.wellKnownNodeInfo
    #expect(endpoint.path() == ".well-known/nodeinfo")
    #expect(endpoint.queryItems() == nil)
    #expect(endpoint.jsonValue == nil)
  }
  
  @Test("NodeInfo nodeInfo endpoint path")
  func testNodeInfoPath() {
    let endpoint = NodeInfo.nodeInfo(url: "nodeinfo/2.0")
    #expect(endpoint.path() == "nodeinfo/2.0")
    #expect(endpoint.queryItems() == nil)
    #expect(endpoint.jsonValue == nil)
  }
  
  @Test("NodeInfo endpoint with custom path")
  func testNodeInfoCustomPath() {
    let endpoint = NodeInfo.nodeInfo(url: "custom/nodeinfo/path")
    #expect(endpoint.path() == "custom/nodeinfo/path")
  }
}