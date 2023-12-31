import Bodega
import Models
import Network
import SwiftUI

public actor TimelineCache {
  private func storageFor(_ client: String) -> SQLiteStorageEngine {
    SQLiteStorageEngine.default(appendingPath: client)
  }

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  public init() {}

  public func cachedPostsCount(for client: String) async -> Int {
    await storageFor(client).allKeys().count
  }

  public func clearCache(for client: String) async {
    let engine = storageFor(client)
    do {
      try await engine.removeAllData()
    } catch {}
  }

  func set(statuses: [Status], client: String) async {
    guard !statuses.isEmpty else { return }
    let statuses = statuses.prefix(upTo: min(600, statuses.count - 1)).map { $0 }
    do {
      let engine = storageFor(client)
      try await engine.removeAllData()
      let itemKeys = statuses.map { CacheKey($0[keyPath: \.id]) }
      let dataAndKeys = try zip(itemKeys, statuses)
        .map { try (key: $0, data: encoder.encode($1)) }
      try await engine.write(dataAndKeys)
    } catch {}
  }

  func getStatuses(for client: String) async -> [Status]? {
    let engine = storageFor(client)
    do {
      return try await engine
        .readAllData()
        .map { try decoder.decode(Status.self, from: $0) }
        .sorted(by: { $0.createdAt.asDate > $1.createdAt.asDate })
    } catch {
      return nil
    }
  }

  func setLatestSeenStatuses(ids: [String], for client: Client) {
    UserDefaults.standard.set(ids, forKey: "timeline-last-seen-\(client.id)")
  }

  func getLatestSeenStatus(for client: Client) -> [String]? {
    UserDefaults.standard.array(forKey: "timeline-last-seen-\(client.id)") as? [String]
  }
}

// Quiets down the warnings from this one. Bodega is nicely async so we don't
// want to just use `@preconcurrency`, but the CacheKey type is (incorrectly)
// not marked as `Sendable`---it's a value type containing two `String`
// properties.
extension Bodega.CacheKey: @unchecked Sendable {}
