@testable import Timeline
import XCTest

final class TimelineTests: XCTestCase {
  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    let tl = TimelineFilter.digest
    XCTAssertEqual(tl.title(), "Hello, World!")
  }
}
