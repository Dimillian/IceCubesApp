import Models
import NetworkClient
import Testing
import XCTest

@testable import Timeline

@MainActor
@Suite("Timeline View Model tests")
struct Tests {
  func makeSubject() -> TimelineViewModel {
    let subject = TimelineViewModel()
    let client = MastodonClient(server: "localhost")
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
      language: status.language,
      quote: nil,
      quotesCount: nil,
      quoteApproval: nil)
    await subject.handleEvent(event: StreamEventStatusUpdate(status: status))
    let statuses = await subject.datasource.get()
    count = await subject.datasource.count()
    #expect(count == 1)
    #expect(statuses.first?.content.asRawText == "test")
  }

  @Test
  func autoFetchesWhenFilteredStatusesAreEmpty() async throws {
    let contentFilter = TimelineContentFilter.shared
    contentFilter.showBoosts = true
    contentFilter.showReplies = true
    contentFilter.showThreads = true
    contentFilter.showQuotePosts = true

    let hiddenFirstPage = (0..<50).map { makeStatus(id: "hidden-first-\($0)", hidden: true) }
    let hiddenSecondPage = (0..<40).map { makeStatus(id: "hidden-next-\($0)", hidden: true) }
    let visibleThirdPage = [makeStatus(id: "visible-0", hidden: false)]

    let fetcher = MockTimelineStatusFetcher(
      firstPage: hiddenFirstPage,
      nextPages: [hiddenSecondPage, visibleThirdPage])

    let subject = TimelineViewModel(statusFetcher: fetcher)
    subject.client = MastodonClient(server: "localhost")
    await subject.reset()

    await subject.fetchNewestStatuses(pullToRefresh: false)

    let filteredItems = await subject.datasource.getFilteredItems()
    #expect(!filteredItems.isEmpty)
    #expect(await fetcher.nextPageCallCount() >= 2)
  }
}
