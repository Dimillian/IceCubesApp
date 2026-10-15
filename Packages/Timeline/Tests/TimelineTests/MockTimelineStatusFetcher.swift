import Models
import NetworkClient

@testable import Timeline

actor MockTimelineStatusFetcher: TimelineStatusFetching {
  private let firstPage: [Status]
  private let nextPages: [[Status]]
  private let firstPageError: Error?
  private var nextPageCalls: Int = 0

  init(firstPage: [Status], nextPages: [[Status]], firstPageError: Error? = nil) {
    self.firstPage = firstPage
    self.nextPages = nextPages
    self.firstPageError = firstPageError
  }

  func fetchFirstPage(client: MastodonClient?, timeline: TimelineFilter) async throws -> [Status] {
    if let firstPageError {
      throw firstPageError
    }
    return firstPage
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
