import Boutique
import Models
import Network
import SwiftUI

public actor TimelineCache {
  public static let shared: TimelineCache = .init()

  private func storageFor(_ client: Client) -> SQLiteStorageEngine {
    SQLiteStorageEngine.default(appendingPath: client.id)
  }

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  private init() {}

  public func cachedPostsCount(for client: Client) async -> Int {
    await storageFor(client).allKeys().count
  }

  public func clearCache(for client: Client) async {
    let engine = storageFor(client)
    do {
      try await engine.removeAllData()
    } catch {}
  }

  func set(statuses: [Status], client: Client) async {
    guard !statuses.isEmpty else { return }
    let statuses = statuses.prefix(upTo: min(600, statuses.count - 1)).map { $0 }
    do {
      let engine = storageFor(client)
      try await engine.removeAllData()
      let itemKeys = statuses.map { CacheKey($0[keyPath: \.id]) }
      let dataAndKeys = try zip(itemKeys, statuses)
        .map { (key: $0, data: try encoder.encode($1)) }
      try await engine.write(dataAndKeys)
    } catch {}
  }

  func getStatuses(for client: Client) async -> [Status]? {
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
