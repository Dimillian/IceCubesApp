import Models
import NetworkClient

@testable import Timeline

actor MockTimelineStatusFetcher: TimelineStatusFetching {
  private let firstPage: [Status]
  private let nextPages: [[Status]]
  private var nextPageCalls: Int = 0
  private var gapPages: [[Status]]
  private(set) var gapCalls: [(gap: TimelineGap, direction: GapFillDirection, limit: Int)] = []

  init(firstPage: [Status], nextPages: [[Status]], gapPages: [[Status]] = []) {
    self.firstPage = firstPage
    self.nextPages = nextPages
    self.gapPages = gapPages
  }

  func fetchGap(
    client: MastodonClient?,
    timeline: TimelineFilter,
    gap: TimelineGap,
    direction: GapFillDirection,
    limit: Int
  ) async throws -> [Status] {
    gapCalls.append((gap, direction, limit))
    guard !gapPages.isEmpty else { return [] }
    return gapPages.removeFirst()
  }

  func fetchFirstPage(client: MastodonClient?, timeline: TimelineFilter) async throws -> [Status] {
    firstPage
  }

  func fetchNewPages(
    client: MastodonClient?,
    timeline: TimelineFilter,
    minId: String,
    maxPages: Int
  ) async throws -> [Status] {
    []
  }

  func fetchNextPage(
    client: MastodonClient?,
    timeline: TimelineFilter,
    lastId: String,
    offset: Int
  ) async throws -> [Status] {
    defer { nextPageCalls += 1 }
    guard nextPageCalls < nextPages.count else { return [] }
    return nextPages[nextPageCalls]
  }

  func nextPageCallCount() -> Int {
    nextPageCalls
  }
}
