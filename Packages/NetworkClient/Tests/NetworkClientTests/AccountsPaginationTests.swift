@testable import NetworkClient
import XCTest

final class AccountsPaginationTests: XCTestCase {
  func testBlockedAccountsInitialPageHasNoCursor() {
    XCTAssertEqual(Accounts.blockList(maxId: nil).path(), "blocks")
    XCTAssertNil(Accounts.blockList(maxId: nil).queryItems())
  }

  func testBlockedAccountsNextPageUsesLinkCursor() throws {
    let link = LinkHandler(
      rawLink: "<https://example.com/api/v1/blocks?max_id=441449>; rel=\"next\"",
    )
    let cursor = try XCTUnwrap(link.maxId)
    let endpoint = Accounts.blockList(maxId: cursor)

    XCTAssertEqual(endpoint.path(), "blocks")
    XCTAssertEqual(endpoint.queryItems(), [URLQueryItem(name: "max_id", value: "441449")])
  }

  func testMutedAccountsInitialPageHasNoCursor() {
    XCTAssertEqual(Accounts.muteList(maxId: nil).path(), "mutes")
    XCTAssertNil(Accounts.muteList(maxId: nil).queryItems())
  }

  func testMutedAccountsNextPageUsesLinkCursor() throws {
    let link = LinkHandler(
      rawLink: "<https://example.com/api/v1/mutes?max_id=987654>; rel=\"next\"",
    )
    let cursor = try XCTUnwrap(link.maxId)
    let endpoint = Accounts.muteList(maxId: cursor)

    XCTAssertEqual(endpoint.path(), "mutes")
    XCTAssertEqual(endpoint.queryItems(), [URLQueryItem(name: "max_id", value: "987654")])
  }
}
