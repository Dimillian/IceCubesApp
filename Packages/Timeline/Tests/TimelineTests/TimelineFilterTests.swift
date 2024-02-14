import Models
import Network
@testable import Timeline
import XCTest

final class TimelineFilterTests: XCTestCase {
  func testCodableHome() throws {
    XCTAssertTrue(try testCodableOn(filter: .home))
    XCTAssertTrue(try testCodableOn(filter: .local))
    XCTAssertTrue(try testCodableOn(filter: .federated))
    XCTAssertTrue(try testCodableOn(filter: .remoteLocal(server: "me.dm", filter: .local)))
    XCTAssertTrue(try testCodableOn(filter: .tagGroup(title: "test", tags: ["test"], symbolName: nil)))
    XCTAssertTrue(try testCodableOn(filter: .tagGroup(title: "test", tags: ["test"], symbolName: "test")))
    XCTAssertTrue(try testCodableOn(filter: .hashtag(tag: "test", accountId: nil)))
    XCTAssertTrue(try testCodableOn(filter: .list(list: .init(id: "test", title: "test"))))
  }

  private func testCodableOn(filter: TimelineFilter) throws -> Bool {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(filter)
    let newFilter = try decoder.decode(TimelineFilter.self, from: data)
    return newFilter == filter
  }
}
