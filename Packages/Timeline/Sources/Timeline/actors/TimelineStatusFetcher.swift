import Foundation
import Models
import NetworkClient

protocol TimelineStatusFetching: Sendable {
  func fetchFirstPage(
    client: MastodonClient?,
    timeline: TimelineFilter
  ) async throws -> [Status]
  func fetchNewPages(
    client: MastodonClient?,
    timeline: TimelineFilter,
    minId: String,
    maxPages: Int
  ) async throws -> [Status]
  func fetchNextPage(
    client: MastodonClient?,
    timeline: TimelineFilter,
    lastId: String,
    offset: Int
  ) async throws -> [Status]
}

enum StatusFetcherError: Error {
  case noClientAvailable
}

struct TimelineStatusFetcher: TimelineStatusFetching {
  func fetchFirstPage(client: MastodonClient?, timeline: TimelineFilter) async throws -> [Status] {
    guard let client = client else { throw StatusFetcherError.noClientAvailable }
    return try await client.get(
      endpoint: timeline.endpoint(
        sinceId: nil,
        maxId: nil,
        minId: nil,
        offset: 0,
        limit: 50))
  }

  func fetchNewPages(client: MastodonClient?, timeline: TimelineFilter, minId: String, maxPages: Int)
    async throws -> [Status]
  {
    guard let client = client else { throw StatusFetcherError.noClientAvailable }
    guard maxPages > 0 else { return [] }

    var pagesLoaded = 0
    var allStatuses: [Status] = []
    var latestMinId = minId

    while !Task.isCancelled, pagesLoaded < maxPages {
      let newStatuses: [Status] = try await client.get(
        endpoint: timeline.endpoint(
          sinceId: nil,
          maxId: nil,
          minId: latestMinId,
          offset: nil,
          limit: 40
        ))

      if newStatuses.isEmpty { break }

      pagesLoaded += 1
      allStatuses.insert(contentsOf: newStatuses, at: 0)
      latestMinId = newStatuses.first?.id ?? latestMinId
    }
    return allStatuses
  }

  func fetchNextPage(client: MastodonClient?, timeline: TimelineFilter, lastId: String, offset: Int)
    async throws -> [Status]
  {
    guard let client = client else { throw StatusFetcherError.noClientAvailable }
    return try await client.get(
      endpoint: timeline.endpoint(
        sinceId: nil,
        maxId: lastId,
        minId: nil,
        offset: offset,
        limit: 40))
  }
}
