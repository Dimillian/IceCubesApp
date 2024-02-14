import Bodega
import Models
import Network
import SwiftUI

public actor TimelineCache {
  private func storageFor(_ client: String, _ filter: String) -> SQLiteStorageEngine {
    if filter == "Home" {
      SQLiteStorageEngine.default(appendingPath: "\(client)")
    } else {
      SQLiteStorageEngine.default(appendingPath: "\(client)/\(filter)")
    }
  }

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  public init() {}

  public func cachedPostsCount(for client: String) async -> Int {
    do {
      let directory = FileManager.Directory.defaultStorageDirectory(appendingPath: client).url
      let content = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
      var total: Int = await storageFor(client, "Home").allKeys().count
      for storage in content {
        if !storage.lastPathComponent.hasSuffix("sqlite3") {
          total += await storageFor(client, storage.lastPathComponent).allKeys().count
        }
      }
      return total
    } catch {
      return 0
    }
  }

  public func clearCache(for client: String) async {
    let directory = FileManager.Directory.defaultStorageDirectory(appendingPath: client)
    try? FileManager.default.removeItem(at: directory.url)
  }

  public func clearCache(for client: String, filter: String) async {
    let engine = storageFor(client, filter)
    do {
      try await engine.removeAllData()
    } catch {}
  }

  func set(statuses: [Status], client: String, filter: String) async {
    guard !statuses.isEmpty else { return }
    let statuses = statuses.prefix(upTo: min(600, statuses.count - 1)).map { $0 }
    do {
      let engine = storageFor(client, filter)
      try await engine.removeAllData()
      let itemKeys = statuses.map { CacheKey($0[keyPath: \.id]) }
      let dataAndKeys = try zip(itemKeys, statuses)
        .map { try (key: $0, data: encoder.encode($1)) }
      try await engine.write(dataAndKeys)
    } catch {}
  }

  func getStatuses(for client: String, filter: String) async -> [Status]? {
    let engine = storageFor(client, filter)
    do {
      return try await engine
        .readAllData()
        .map { try decoder.decode(Status.self, from: $0) }
        .sorted(by: { $0.createdAt.asDate > $1.createdAt.asDate })
    } catch {
      return nil
    }
  }

  func setLatestSeenStatuses(_ statuses: [Status], for client: Client, filter: String) {
    let statuses = statuses.sorted(by: { $0.createdAt.asDate > $1.createdAt.asDate })
    if filter == "Home" {
      UserDefaults.standard.set(statuses.map { $0.id }, forKey: "timeline-last-seen-\(client.id)")
    } else {
      UserDefaults.standard.set(statuses.map { $0.id }, forKey: "timeline-last-seen-\(client.id)-\(filter)")
    }
  }

  func getLatestSeenStatus(for client: Client, filter: String) -> [String]? {
    if filter == "Home" {
      UserDefaults.standard.array(forKey: "timeline-last-seen-\(client.id)") as? [String]
    } else {
      UserDefaults.standard.array(forKey: "timeline-last-seen-\(client.id)-\(filter)") as? [String]
    }
  }
}

// Quiets down the warnings from this one. Bodega is nicely async so we don't
// want to just use `@preconcurrency`, but the CacheKey type is (incorrectly)
// not marked as `Sendable`---it's a value type containing two `String`
// properties.
extension Bodega.CacheKey: @unchecked Sendable {}
