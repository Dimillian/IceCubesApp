import Bodega
import Models
import NetworkClient
import SwiftUI

public actor TimelineCache {
  private struct CachedTimelineItem: Codable {
    enum Kind: String, Codable { case status, gap }

    var kind: Kind
    var status: Status?
    var gap: CachedGap?
  }

  private struct CachedGap: Codable {
    var sinceId: String
    var maxId: String
  }

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
      let content = try FileManager.default.contentsOfDirectory(
        at: directory, includingPropertiesForKeys: nil)
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

  func set(items: [TimelineItem], client: String, filter: String) async {
    guard items.contains(where: { $0.status != nil }) else { return }
    do {
      let engine = storageFor(client, filter)
      try await engine.removeAllData()
      let payload = try encoder.encode(prepareItemsForCaching(items))
      try await engine.write([(CacheKey("items"), payload)])
    } catch {}
  }

  func getItems(for client: String, filter: String) async -> [TimelineItem]? {
    let engine = storageFor(client, filter)
    do {
      let storedData = await engine.readAllData()
      guard let data = storedData.first else { return nil }
      return try restoreItems(from: data)
    } catch {
      return nil
    }
  }

  func setLatestSeenStatuses(_ statuses: [Status], for client: MastodonClient, filter: String) {
    let statuses = statuses.sorted(by: { $0.createdAt.asDate > $1.createdAt.asDate })
    if filter == "Home" {
      UserDefaults.standard.set(statuses.map { $0.id }, forKey: "timeline-last-seen-\(client.id)")
    } else {
      UserDefaults.standard.set(
        statuses.map { $0.id }, forKey: "timeline-last-seen-\(client.id)-\(filter)")
    }
  }

  func getLatestSeenStatus(for client: MastodonClient, filter: String) -> [String]? {
    if filter == "Home" {
      UserDefaults.standard.array(forKey: "timeline-last-seen-\(client.id)") as? [String]
    } else {
      UserDefaults.standard.array(forKey: "timeline-last-seen-\(client.id)-\(filter)") as? [String]
    }
  }
}

// MARK: - Encoding helpers

private extension TimelineCache {
  var maxCachedStatuses: Int { 800 }

  private func prepareItemsForCaching(_ items: [TimelineItem]) -> [CachedTimelineItem] {
    limitedItems(items, limit: maxCachedStatuses).map { item in
      switch item {
      case .status(let status):
        return CachedTimelineItem(kind: .status, status: status, gap: nil)
      case .gap(let gap):
        let cachedGap = CachedGap(
          sinceId: gap.sinceId,
          maxId: gap.maxId)
        return CachedTimelineItem(kind: .gap, status: nil, gap: cachedGap)
      }
    }
  }

  private func restoreItems(from data: Data) throws -> [TimelineItem] {
    let cachedItems = try decoder.decode([CachedTimelineItem].self, from: data)
    return cachedItems.compactMap { item in
      switch item.kind {
      case .status:
        if let status = item.status {
          return .status(status)
        }
        return nil
      case .gap:
        guard let gap = item.gap else { return nil }
        return .gap(
          TimelineGap(
            sinceId: gap.sinceId.isEmpty ? nil : gap.sinceId,
            maxId: gap.maxId))
      }
    }
  }

  private func limitedItems(_ items: [TimelineItem], limit: Int) -> [TimelineItem] {
    guard limit > 0 else { return [] }

    var collected: [TimelineItem] = []
    var statusCount = 0

    for item in items {
      switch item {
      case .status:
        guard statusCount < limit else { continue }
        collected.append(item)
        statusCount += 1
      case .gap:
        guard statusCount > 0 else { continue }
        collected.append(item)
        if statusCount >= limit { return collected }
      }
    }

    return collected
  }
}
