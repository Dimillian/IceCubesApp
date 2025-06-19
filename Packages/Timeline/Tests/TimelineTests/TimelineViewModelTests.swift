import Models
import Network
import Testing
import XCTest

@testable import Timeline

@MainActor
@Suite("Timeline View Model tests")
struct Tests {
  func makeSubject() -> TimelineViewModel {
    let subject = TimelineViewModel()
    let client = Client(server: "localhost")
    subject.client = client
    subject.timeline = .home
    subject.timelineTask?.cancel()
    return subject
  }

  /*
  @Test
  func streamEventInsertNewStatus() async throws {
    let subject = makeSubject()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    await subject.datasource.append(.placeholder())
    var count = await subject.datasource.count()
    #expect(count == 1)
    await subject.handleEvent(event: StreamEventUpdate(status: .placeholder()))
    count = await subject.datasource.count()
    #expect(count == 2)
  }
   */

  @Test
  func streamEventInsertDuplicateStatus() async throws {
    let subject = makeSubject()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    let status = Status.placeholder()
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    #expect(count == 1)
    await subject.handleEvent(event: StreamEventUpdate(status: status))
    count = await subject.datasource.count()
    #expect(count == 1)
  }

  @Test
  func streamEventRemove() async throws {
    let subject = makeSubject()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    let status = Status.placeholder()
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    #expect(count == 1)
    await subject.handleEvent(event: StreamEventDelete(status: status.id))
    count = await subject.datasource.count()
    #expect(count == 0)
  }

  @Test
  func streamEventUpdateStatus() async throws {
    let subject = makeSubject()
    var status = Status.placeholder()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    #expect(count == 1)
    status = .init(
      id: status.id,
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
    #expect(count == 1)
    #expect(statuses.first?.content.asRawText == "test")
  }
}
