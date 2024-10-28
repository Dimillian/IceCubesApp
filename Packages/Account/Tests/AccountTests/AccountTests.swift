import XCTest

@testable import Account

final class AccountTests: XCTestCase {
  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    XCTAssertEqual(Account().text, "Hello, World!")
  }
}
