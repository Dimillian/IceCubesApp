import Testing
import XCTest
@testable import Env
@testable import Models

@MainActor
@Suite("CurrentInstance GoToSocial Detection Tests")
struct CurrentInstanceTests {
  
  @Test("NodeInfo detection - GoToSocial")
  func testNodeInfoDetectionGoToSocial() {
    let currentInstance = CurrentInstance.shared
    
    // Create mock NodeInfo for GoToSocial
    let nodeInfo = NodeInfo(
      version: "2.0",
      software: NodeInfo.Software(name: "gotosocial", version: "0.19.1"),
      protocols: ["activitypub"],
      usage: nil,
      openRegistrations: false,
      metadata: nil
    )
    
    // Create mock Instance
    let instance = Instance(
      title: "Test GoToSocial",
      description: "Test instance",
      shortDescription: "Test",
      email: "admin@test.com",
      version: "0.19.1",
      stats: Instance.Stats(userCount: 1, statusCount: 1, domainCount: 1),
      languages: ["en"],
      registrations: false,
      thumbnail: nil,
      configuration: nil,
      rules: nil,
      urls: nil,
      uri: "test.social"
    )
    
    // Set the test data
    currentInstance.nodeInfo = nodeInfo
    currentInstance.instance = instance
    
    // Test detection
    #expect(currentInstance.isEditSupported == true)
    #expect(currentInstance.isFiltersSupported == true)
    #expect(currentInstance.isEditAltTextSupported == true)
    #expect(currentInstance.isNotificationsFilterSupported == true)
    #expect(currentInstance.isLinkTimelineSupported == false) // GoToSocial doesn't support this
  }
  
  @Test("NodeInfo detection - Mastodon")
  func testNodeInfoDetectionMastodon() {
    let currentInstance = CurrentInstance.shared
    
    // Create mock NodeInfo for Mastodon
    let nodeInfo = NodeInfo(
      version: "2.0",
      software: NodeInfo.Software(name: "mastodon", version: "4.5.0"),
      protocols: ["activitypub"],
      usage: nil,
      openRegistrations: true,
      metadata: nil
    )
    
    // Create mock Instance
    let instance = Instance(
      title: "Test Mastodon",
      description: "Test instance",
      shortDescription: "Test",
      email: "admin@test.com",
      version: "4.5.0",
      stats: Instance.Stats(userCount: 1000, statusCount: 10000, domainCount: 100),
      languages: ["en"],
      registrations: true,
      thumbnail: nil,
      configuration: nil,
      rules: nil,
      urls: nil,
      uri: "mastodon.test"
    )
    
    // Set the test data
    currentInstance.nodeInfo = nodeInfo
    currentInstance.instance = instance
    
    // Test detection
    #expect(currentInstance.isEditSupported == true)
    #expect(currentInstance.isFiltersSupported == true)
    #expect(currentInstance.isEditAltTextSupported == true)
    #expect(currentInstance.isNotificationsFilterSupported == true)
    #expect(currentInstance.isLinkTimelineSupported == true)
  }
  
  @Test("Fallback detection - no NodeInfo")
  func testFallbackDetectionNoNodeInfo() {
    let currentInstance = CurrentInstance.shared
    
    // Create mock Instance without NodeInfo
    let instance = Instance(
      title: "Unknown Server",
      description: "Test instance",
      shortDescription: "Test",
      email: "admin@test.com",
      version: "1.0.0",
      stats: Instance.Stats(userCount: 100, statusCount: 1000, domainCount: 10),
      languages: ["en"],
      registrations: true,
      thumbnail: nil,
      configuration: nil,
      rules: nil,
      urls: nil,
      uri: "unknown.test"
    )
    
    // Set only instance data (no NodeInfo)
    currentInstance.nodeInfo = nil
    currentInstance.instance = instance
    
    // Test fallback to Mastodon behavior
    #expect(currentInstance.isEditSupported == false) // Version 1.0.0 < 3.5
    #expect(currentInstance.isFiltersSupported == false) // Version 1.0.0 < 4.0
    #expect(currentInstance.isEditAltTextSupported == false) // Version 1.0.0 < 4.1
    #expect(currentInstance.isNotificationsFilterSupported == false) // Version 1.0.0 < 4.3
    #expect(currentInstance.isLinkTimelineSupported == false) // Version 1.0.0 < 4.3
  }
  
  @Test("GoToSocial version parsing")
  func testGoToSocialVersionParsing() {
    let currentInstance = CurrentInstance.shared
    
    // Test various GoToSocial version formats
    let testCases = [
      ("0.19.1+git-6574dc8", true),  // Current with git hash
      ("0.19.0", true),              // Stable release
      ("0.18.3", true),              // Previous stable
      ("0.11.0", true),              // Filters support start
      ("0.8.0", true),               // Edit support start
      ("0.7.9", false),              // Before edit support
    ]
    
    for (version, expectedEditSupport) in testCases {
      // Create NodeInfo for GoToSocial
      let nodeInfo = NodeInfo(
        version: "2.0",
        software: NodeInfo.Software(name: "gotosocial", version: version),
        protocols: ["activitypub"],
        usage: nil,
        openRegistrations: false,
        metadata: nil
      )
      
      let instance = Instance(
        title: "Test GoToSocial",
        description: "Test",
        shortDescription: "Test",
        email: "admin@test.com",
        version: version,
        stats: Instance.Stats(userCount: 1, statusCount: 1, domainCount: 1),
        languages: ["en"],
        registrations: false,
        thumbnail: nil,
        configuration: nil,
        rules: nil,
        urls: nil,
        uri: "test.social"
      )
      
      currentInstance.nodeInfo = nodeInfo
      currentInstance.instance = instance
      
      #expect(currentInstance.isEditSupported == expectedEditSupport, 
              "Edit support for GoToSocial \(version) should be \(expectedEditSupport)")
    }
  }
  
  @Test("NodeInfo discovery URL extraction")
  func testNodeInfoDiscoveryURLExtraction() {
    let discovery = NodeInfoDiscovery(links: [
      NodeInfoDiscovery.Link(
        rel: "http://nodeinfo.diaspora.software/ns/schema/2.0",
        href: "https://gts.superseriousbusiness.org/nodeinfo/2.0"
      ),
      NodeInfoDiscovery.Link(
        rel: "http://nodeinfo.diaspora.software/ns/schema/2.1",
        href: "https://gts.superseriousbusiness.org/nodeinfo/2.1"
      )
    ])
    
    #expect(discovery.nodeInfo20URL == "https://gts.superseriousbusiness.org/nodeinfo/2.0")
  }
  
  @Test("NodeInfo discovery - no 2.0 schema")
  func testNodeInfoDiscoveryNo20Schema() {
    let discovery = NodeInfoDiscovery(links: [
      NodeInfoDiscovery.Link(
        rel: "http://nodeinfo.diaspora.software/ns/schema/2.1",
        href: "https://example.com/nodeinfo/2.1"
      )
    ])
    
    #expect(discovery.nodeInfo20URL == nil)
  }
  
  @Test("Case insensitive software name detection")
  func testCaseInsensitiveSoftwareDetection() {
    let currentInstance = CurrentInstance.shared
    
    let testCases = ["gotosocial", "GoToSocial", "GOTOSOCIAL", "GoToSocial"]
    
    for softwareName in testCases {
      let nodeInfo = NodeInfo(
        version: "2.0",
        software: NodeInfo.Software(name: softwareName, version: "0.19.1"),
        protocols: ["activitypub"],
        usage: nil,
        openRegistrations: false,
        metadata: nil
      )
      
      let instance = Instance(
        title: "Test",
        description: "Test",
        shortDescription: "Test",
        email: "admin@test.com",
        version: "0.19.1",
        stats: Instance.Stats(userCount: 1, statusCount: 1, domainCount: 1),
        languages: ["en"],
        registrations: false,
        thumbnail: nil,
        configuration: nil,
        rules: nil,
        urls: nil,
        uri: "test.social"
      )
      
      currentInstance.nodeInfo = nodeInfo
      currentInstance.instance = instance
      
      #expect(currentInstance.isEditSupported == true,
              "Should detect GoToSocial regardless of case: \(softwareName)")
    }
  }
}