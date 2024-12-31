import Foundation
import Models
import Network

protocol TimelineStatusFetching: Sendable {
  func fetchFirstPage(
    client: Client?,
    timeline: TimelineFilter
  ) async throws -> [Status]
  func fetchNewPages(
    client: Client?,
    timeline: TimelineFilter,
    minId: String,
    maxPages: Int
  ) async throws -> [Status]
  func fetchNextPage(
    client: Client?,
    timeline: TimelineFilter,
    lastId: String,
    offset: Int
  ) async throws -> [Status]
}

enum StatusFetcherError: Error {
  case noClientAvailable
}

struct TimelineStatusFetcher: TimelineStatusFetching {
  func fetchFirstPage(client: Client?, timeline: TimelineFilter) async throws -> [Status] {
    guard let client = client else { throw StatusFetcherError.noClientAvailable }
    return try await client.get(
      endpoint: timeline.endpoint(
        sinceId: nil,
        maxId: nil,
        minId: nil,
        offset: 0,
        limit: 40))
  }

  func fetchNewPages(client: Client?, timeline: TimelineFilter, minId: String, maxPages: Int)
    async throws -> [Status]
  {
    guard let client = client else { throw StatusFetcherError.noClientAvailable }
    var allStatuses: [Status] = []
    var latestMinId = minId
    for _ in 1...maxPages {
      if Task.isCancelled { break }

      let newStatuses: [Status] = try await client.get(
        endpoint: timeline.endpoint(
          sinceId: nil,
          maxId: nil,
          minId: latestMinId,
          offset: nil,
          limit: 40
        ))

      if newStatuses.isEmpty { break }

      allStatuses.insert(contentsOf: newStatuses, at: 0)
      latestMinId = newStatuses.first?.id ?? latestMinId
    }
    return allStatuses
  }

  func fetchNextPage(client: Client?, timeline: TimelineFilter, lastId: String, offset: Int)
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
