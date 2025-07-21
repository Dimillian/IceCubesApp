import Testing
import Foundation
@testable import Models

@Suite("NodeInfo Model Tests")
struct NodeInfoTests {
  
  @Test("NodeInfo decoding - GoToSocial")
  func testNodeInfoDecodingGoToSocial() throws {
    let json = """
    {
      "version": "2.0",
      "software": {
        "name": "gotosocial",
        "version": "0.19.1+git-6574dc8"
      },
      "protocols": ["activitypub"],
      "services": {
        "inbound": [],
        "outbound": []
      },
      "openRegistrations": false,
      "usage": {
        "users": {
          "total": 5
        },
        "localPosts": 5894
      },
      "metadata": {}
    }
    """
    
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    
    let nodeInfo = try decoder.decode(NodeInfo.self, from: data)
    
    #expect(nodeInfo.version == "2.0")
    #expect(nodeInfo.software.name == "gotosocial")
    #expect(nodeInfo.software.version == "0.19.1+git-6574dc8")
    #expect(nodeInfo.protocols == ["activitypub"])
    #expect(nodeInfo.openRegistrations == false)
    #expect(nodeInfo.usage?.users?.total == 5)
    #expect(nodeInfo.usage?.localPosts == 5894)
  }
  
  @Test("NodeInfo decoding - Mastodon")
  func testNodeInfoDecodingMastodon() throws {
    let json = """
    {
      "version": "2.0",
      "software": {
        "name": "mastodon",
        "version": "4.5.0-nightly.2025-07-17"
      },
      "protocols": ["activitypub"],
      "services": {
        "outbound": [],
        "inbound": []
      },
      "usage": {
        "users": {
          "total": 2811979,
          "activeMonth": 271572,
          "activeHalfyear": 807071
        },
        "localPosts": 139167975
      },
      "openRegistrations": true,
      "metadata": {
        "nodeName": "Mastodon",
        "nodeDescription": "The original server operated by the Mastodon gGmbH non-profit"
      }
    }
    """
    
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    
    let nodeInfo = try decoder.decode(NodeInfo.self, from: data)
    
    #expect(nodeInfo.version == "2.0")
    #expect(nodeInfo.software.name == "mastodon")
    #expect(nodeInfo.software.version == "4.5.0-nightly.2025-07-17")
    #expect(nodeInfo.protocols == ["activitypub"])
    #expect(nodeInfo.openRegistrations == true)
    #expect(nodeInfo.usage?.users?.total == 2811979)
    #expect(nodeInfo.usage?.users?.activeMonth == 271572)
    #expect(nodeInfo.usage?.localPosts == 139167975)
  }
  
  @Test("NodeInfoDiscovery decoding")
  func testNodeInfoDiscoveryDecoding() throws {
    let json = """
    {
      "links": [
        {
          "rel": "http://nodeinfo.diaspora.software/ns/schema/2.0",
          "href": "https://gts.superseriousbusiness.org/nodeinfo/2.0"
        },
        {
          "rel": "http://nodeinfo.diaspora.software/ns/schema/2.1",
          "href": "https://gts.superseriousbusiness.org/nodeinfo/2.1"
        }
      ]
    }
    """
    
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    
    let discovery = try decoder.decode(NodeInfoDiscovery.self, from: data)
    
    #expect(discovery.links.count == 2)
    #expect(discovery.links[0].rel == "http://nodeinfo.diaspora.software/ns/schema/2.0")
    #expect(discovery.links[0].href == "https://gts.superseriousbusiness.org/nodeinfo/2.0")
    #expect(discovery.nodeInfo20URL == "https://gts.superseriousbusiness.org/nodeinfo/2.0")
  }
  
  @Test("NodeInfo minimal structure")
  func testNodeInfoMinimalStructure() throws {
    let json = """
    {
      "version": "2.0",
      "software": {
        "name": "gotosocial",
        "version": "0.19.1"
      },
      "protocols": ["activitypub"],
      "openRegistrations": false
    }
    """
    
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    
    let nodeInfo = try decoder.decode(NodeInfo.self, from: data)
    
    #expect(nodeInfo.version == "2.0")
    #expect(nodeInfo.software.name == "gotosocial")
    #expect(nodeInfo.software.version == "0.19.1")
    #expect(nodeInfo.protocols == ["activitypub"])
    #expect(nodeInfo.openRegistrations == false)
    #expect(nodeInfo.usage == nil)
    #expect(nodeInfo.metadata == nil)
  }
}