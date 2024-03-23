import Models
import Network
@testable import Timeline
import XCTest

@MainActor
final class TimelineViewModelTests: XCTestCase {
  var subject = TimelineViewModel()

  override func setUp() async throws {
    subject = TimelineViewModel()
    let client = Client(server: "localhost")
    subject.client = client
    subject.timeline = .home
    subject.isTimelineVisible = true
    subject.timelineTask?.cancel()
  }

  func testStreamEventInsertNewStatus() async throws {
    let isEmpty = await subject.datasource.isEmpty
    XCTAssertTrue(isEmpty)
    await subject.datasource.append(.placeholder())
    var count = await subject.datasource.count()
    XCTAssertTrue(count == 1)
    await subject.handleEvent(event: StreamEventUpdate(status: .placeholder()))
    count = await subject.datasource.count()
    XCTAssertTrue(count == 2)
  }

  func testStreamEventInsertDuplicateStatus() async throws {
    let isEmpty = await subject.datasource.isEmpty
    XCTAssertTrue(isEmpty)
    let status = Status.placeholder()
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    XCTAssertTrue(count == 1)
    await subject.handleEvent(event: StreamEventUpdate(status: status))
    count = await subject.datasource.count()
    XCTAssertTrue(count == 1)
  }

  func testStreamEventRemove() async throws {
    let isEmpty = await subject.datasource.isEmpty
    XCTAssertTrue(isEmpty)
    let status = Status.placeholder()
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    XCTAssertTrue(count == 1)
    await subject.handleEvent(event: StreamEventDelete(status: status.id))
    count = await subject.datasource.count()
    XCTAssertTrue(count == 0)
  }

  func testStreamEventUpdateStatus() async throws {
    var status = Status.placeholder()
    let isEmpty = await subject.datasource.isEmpty
    XCTAssertTrue(isEmpty)
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    XCTAssertTrue(count == 1)
    status = .init(id: status.id,
                   content: .init(stringValue: "test"),
                   account: status.account,
                   createdAt: status.createdAt,
                   editedAt: status.editedAt,
                   reblog: status.reblog,
                   mediaAttachments: status.mediaAttachments,
                   mentions: status.mentions,
                   repliesCount: status.repliesCount,
                   reblogsCount: status.reblogsCount,
                   favouritesCount: status.favouritesCount,
                   card: status.card,
                   favourited: status.favourited,
                   reblogged: status.reblogged,
                   pinned: status.pinned,
                   bookmarked: status.bookmarked,
                   emojis: status.emojis,
                   url: status.url,
                   application: status.application,
                   inReplyToId: status.inReplyToId,
                   inReplyToAccountId: status.inReplyToAccountId,
                   visibility: status.visibility,
                   poll: status.poll,
                   spoilerText: status.spoilerText,
                   filtered: status.filtered,
                   sensitive: status.sensitive,
                   language: status.language)
    await subject.handleEvent(event: StreamEventStatusUpdate(status: status))
    let statuses = await subject.datasource.get()
    count = await subject.datasource.count()
    XCTAssertTrue(count == 1)
    XCTAssertTrue(statuses.first?.content.asRawText == "test")
  }
}
