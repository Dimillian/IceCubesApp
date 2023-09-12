import Env
import Foundation
import Models
import SwiftUI

public class ReblogCache {
  struct CacheEntry: Codable {
    var reblogId: String
    var postId: String
    var seen: Bool
  }

  public static let shared = ReblogCache()
  private var needsWrite = false

  init() {

    // read any existing cache from disk
    if FileManager.default.fileExists(atPath: cacheFile.path()) {
      do {
        let data = try Data(contentsOf: cacheFile)
        let cacheData = try JSONDecoder().decode([CacheEntry].self, from: data)
        for entry in cacheData {
        
        }
      } catch {
        print("Error reading cache from disc")
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
      self?.saveCache()
    }
  }

  private func saveCache() {
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
  }

  public func cache(_ status: Status, seen: Bool) {
    
  }
}
