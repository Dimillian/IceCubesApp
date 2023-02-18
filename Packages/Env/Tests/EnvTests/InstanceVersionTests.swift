import XCTest

@testable import Env

final class InstanceVersionTests: XCTestCase {

  func testThatNonStandardSemverInstantiatesWithoutError() throws {
    XCTAssertNoThrow(InstanceVersion("4.1.0rc3"))
  }

  func testThatStandardSemverInstantiatesWithoutError() throws {
    XCTAssertNoThrow(InstanceVersion("4.1.0-rc3"))
  }

  func testPrereleasePrecedance() throws {
    let rc1 = InstanceVersion("4.1.0rc1")
    let rc10 = InstanceVersion("4.1.0rc10")
    let nextPatch = InstanceVersion("4.1.1")
    let nextMinor = InstanceVersion("4.2.0")
    
    XCTAssertTrue(rc10 > rc1)
    XCTAssertTrue(nextPatch > rc10)
    XCTAssertTrue(nextMinor > rc10)
    
  }

}
