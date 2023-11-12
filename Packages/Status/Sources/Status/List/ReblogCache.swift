import Env
import Foundation
import LRUCache
import Models
import SwiftUI

public class ReblogCache: @unchecked Sendable {
  struct CacheEntry: Codable {
    var reblogId: String
    var postId: String
    var seen: Bool
  }

  public static let shared = ReblogCache()
  var statusCache = LRUCache<String, CacheEntry>()
  private var needsWrite = false

  init() {
    statusCache.countLimit = 300 // can tune the cache here, 100 is super conservative

    // read any existing cache from disk
    if FileManager.default.fileExists(atPath: cacheFile.path()) {
      do {
        let data = try Data(contentsOf: cacheFile)
        let cacheData = try JSONDecoder().decode([CacheEntry].self, from: data)
        for entry in cacheData {
          statusCache.setValue(entry, forKey: entry.reblogId)
        }
      } catch {
        print("Error reading cache from disc")
      }
      print("Starting cache has \(statusCache.count) items")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
      self?.saveCache()
    }
  }

  private func saveCache() {
    if needsWrite {
      do {
        let data = try JSONEncoder().encode(statusCache.allValues)
        try data.write(to: cacheFile)
      } catch {
        print("Error writing cache to disc")
      }
      needsWrite = false
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
      self?.saveCache()
    }
  }

  private var cacheFile: URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]

    return URL(fileURLWithPath: documentsDirectory.path()).appendingPathComponent("reblog.json")
  }

  @MainActor public func removeDuplicateReblogs(_ statuses: inout [Status]) {
    if !UserPreferences.shared.suppressDupeReblogs {
      return
    }

    var i = statuses.count

    for status in statuses.reversed() {
      // go backwards through the status list
      // so that we can remove items without
      // borking the array

      i -= 1
      if let reblog = status.reblog {
        if let cached = statusCache.value(forKey: reblog.id) {
          // this is already cached
          if cached.postId != status.id, cached.seen {
            // This was posted by someone other than the person we have in the cache
            // and we have seen the items at some point, so we might want to suppress it

            if status.account.id != CurrentAccount.shared.account?.id {
              // just a quick check to makes sure that this wasn't boosted by the current
              // user.  Hiding that would be confusing
              // But assuming it isn't then we can suppress this boost
              print("suppressing: \(reblog.id)/ \(String(describing: reblog.account.displayName)) by \(String(describing: status.account.displayName))")
              statuses.remove(at: i)
              // assert(statuses.count == (ct-1))
            }
          }
        }
        cache(status, seen: false)
      }
    }
  }

  public func cache(_ status: Status, seen: Bool) {
    var wasSeen = false
    var postToCache = status.id

    if let reblog = status.reblog {
      // only caching boosts at the moment.

      if let cached = statusCache.value(forKey: reblog.id) {
        // every time we see it, we refresh it in the list
        // so poplular things are kept in the cache

        wasSeen = cached.seen

        if wasSeen {
          postToCache = cached.postId
          // if we have seen a particular version of the post
          // that's the one we keep
        }
      }
      statusCache.setValue(CacheEntry(reblogId: reblog.id, postId: postToCache, seen: seen || wasSeen), forKey: reblog.id)
      needsWrite = true
    }
  }
}
