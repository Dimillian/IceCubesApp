import Foundation
import Models
import NetworkClient

nonisolated protocol TimelineStatusFetching: Sendable {
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
  /// Fetches one page of statuses inside `gap`, newest first.
  /// `.fromNewer` returns the newest posts of the gap, `.fromOlder` the oldest.
  func fetchGap(
    client: MastodonClient?,
    timeline: TimelineFilter,
    gap: TimelineGap,
    direction: GapFillDirection,
    limit: Int
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

  func fetchGap(
    client: MastodonClient?,
    timeline: TimelineFilter,
    gap: TimelineGap,
    direction: GapFillDirection,
    limit: Int
  ) async throws -> [Status] {
    guard let client = client else { throw StatusFetcherError.noClientAvailable }
    let sinceId = gap.isOpenEnded ? nil : gap.sinceId
    switch direction {
    case .fromOlder where sinceId != nil:
      // `min_id` returns the posts immediately newer than the gap's older bound.
      return try await client.get(
        endpoint: timeline.endpoint(
          sinceId: nil,
          maxId: gap.maxId,
          minId: sinceId,
          offset: nil,
          limit: limit))
    default:
      // `since_id` + `max_id` returns the newest posts below the gap's newer bound.
      return try await client.get(
        endpoint: timeline.endpoint(
          sinceId: sinceId,
          maxId: gap.maxId,
          minId: nil,
          offset: 0,
          limit: limit))
    }
  }
}
