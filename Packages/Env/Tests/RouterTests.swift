@testable import Env
import Network
import SwiftUI
import XCTest

@MainActor
final class RouterTests: XCTestCase {
  func testRouterThreadsURL() {
    let router = RouterPath()
    let url = URL(string: "https://www.threads.net/@dimillian")!
    _ = router.handle(url: url)
    XCTAssertTrue(router.path.isEmpty)
  }

  func testRouterTagsURL() {
    let router = RouterPath()
    let url = URL(string: "https://mastodon.social/tags/test")!
    _ = router.handle(url: url)
    XCTAssertTrue(router.path.first == .hashTag(tag: "test", account: nil))
  }

  func testRouterLocalStatusURL() {
    let router = RouterPath()
    let client = Client(server: "mastodon.social",
                        oauthToken: .init(accessToken: "", tokenType: "", scope: "", createdAt: 0))
    client.addConnections(["mastodon.social"])
    router.client = client
    let url = URL(string: "https://mastodon.social/status/1010384")!
    _ = router.handle(url: url)
    XCTAssertTrue(router.path.first == .statusDetail(id: "1010384"))
  }

  func testRouterRemoteStatusURL() {
    let router = RouterPath()
    let client = Client(server: "mastodon.social",
                        oauthToken: .init(accessToken: "", tokenType: "", scope: "", createdAt: 0))
    client.addConnections(["mastodon.social", "mastodon.online"])
    router.client = client
    let url = URL(string: "https://mastodon.online/status/1010384")!
    _ = router.handle(url: url)
    XCTAssertTrue(router.path.first == .remoteStatusDetail(url: url))
  }

  func testRouteRandomURL() {
    let router = RouterPath()
    let url = URL(string: "https://theweb.com/test/test/one")!
    _ = router.handle(url: url)
    XCTAssertTrue(router.path.isEmpty)
  }
}
