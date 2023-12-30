@testable import Timeline
import XCTest
import Network
import Models

@MainActor
final class TimelineViewModelTests: XCTestCase {
  func testStreamEventInsertNewStatus() async throws {
    let subject = TimelineViewModel()
    let client = Client(server: "localhost")
    subject.client = client
    subject.timeline = .home
    subject.isTimelineVisible = true
        
    let isEmpty = await subject.datasource.isEmpty
    XCTAssertTrue(isEmpty)
    await subject.datasource.append(.placeholder())
    var count = await subject.datasource.count()
    XCTAssertTrue(count == 1)
    await subject.handleEvent(event: StreamEventUpdate(status: .placeholder()))
    count = await subject.datasource.count()
    XCTAssertTrue(count == 2)
  }
}
