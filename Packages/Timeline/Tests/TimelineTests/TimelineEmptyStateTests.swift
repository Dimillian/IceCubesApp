import Models
import NetworkClient
import Testing

@testable import Timeline

@MainActor
@Suite("Empty timeline pagination")
struct TimelineEmptyStateTests {
  @Test
  func emptyFirstPageDoesNotOfferNextPage() async throws {
    let fetcher = MockTimelineStatusFetcher(firstPage: [], nextPages: [])
    let subject = await makeSubject(fetcher: fetcher)

    await subject.fetchNewestStatuses(pullToRefresh: false)

    guard case .displayWithGaps(let items, let nextPageState) = subject.statusesState else {
      Issue.record("A successful empty response should display an empty timeline")
      return
    }
    #expect(items.isEmpty)
    #expect(nextPageState == .none)
    #expect(await fetcher.nextPageCallCount() == 0)
  }

  @Test
  func hiddenStatusesKeepTheirPaginationCursor() async throws {
    let fetcher = MockTimelineStatusFetcher(
      firstPage: [makeStatus(id: "hidden", hidden: true)],
      nextPages: [[makeStatus(id: "visible", hidden: false)]])
    let subject = await makeSubject(fetcher: fetcher)

    await subject.fetchNewestStatuses(pullToRefresh: false)

    guard case .displayWithGaps(let items, let nextPageState) = subject.statusesState else {
      Issue.record("Expected a loaded timeline")
      return
    }
    #expect(items.isEmpty)
    #expect(nextPageState == .hasNextPage)

    try await subject.fetchNextPage()

    #expect(await fetcher.nextPageCallCount() == 1)
    let visibleItems = await subject.datasource.getFilteredItems()
    #expect(visibleItems.compactMap(\.status).map(\.id) == ["visible"])
  }

  @Test
  func deletingLastStatusRemovesNextPage() async throws {
    let status = makeStatus(id: "last-status", hidden: false)
    let fetcher = MockTimelineStatusFetcher(firstPage: [status], nextPages: [])
    let subject = await makeSubject(fetcher: fetcher)
    await subject.fetchNewestStatuses(pullToRefresh: false)

    await subject.handleEvent(event: StreamEventDelete(status: status.id))

    guard case .displayWithGaps(let items, let nextPageState) = subject.statusesState else {
      Issue.record("Expected a loaded timeline after deleting its last status")
      return
    }
    #expect(items.isEmpty)
    #expect(nextPageState == .none)
  }

  @Test
  func gapsWithoutStatusesDoNotOfferNextPage() async throws {
    let fetcher = MockTimelineStatusFetcher(firstPage: [], nextPages: [])
    let subject = await makeSubject(fetcher: fetcher)
    let gap = TimelineGap(sinceId: "newer", maxId: "older")
    await subject.datasource.setItems([.gap(gap)])

    await subject.refreshTimelineContentFilter()

    guard case .displayWithGaps(let items, let nextPageState) = subject.statusesState else {
      Issue.record("Expected the existing gap to remain visible")
      return
    }
    #expect(items.count == 1)
    #expect(items.first?.id == gap.id)
    #expect(nextPageState == .none)
  }

  @Test
  func firstPageFailureRemainsAnError() async throws {
    let fetcher = MockTimelineStatusFetcher(
      firstPage: [], nextPages: [], firstPageError: FetchError.unavailable)
    let subject = await makeSubject(fetcher: fetcher)

    await subject.fetchNewestStatuses(pullToRefresh: false)

    guard case .error = subject.statusesState else {
      Issue.record("A failed request should retain the error state")
      return
    }
    #expect(await fetcher.nextPageCallCount() == 0)
  }

  private func makeSubject(fetcher: MockTimelineStatusFetcher) async -> TimelineViewModel {
    let subject = TimelineViewModel(statusFetcher: fetcher)
    subject.canFilterTimeline = false
    subject.client = MastodonClient(server: "localhost")
    await subject.reset()
    return subject
  }

  private enum FetchError: Error {
    case unavailable
  }
}
