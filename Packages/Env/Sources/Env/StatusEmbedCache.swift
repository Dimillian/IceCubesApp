import Foundation
import Models
import SwiftUI

@MainActor
public class StatusEmbedCache {
  public static let shared = StatusEmbedCache()

  private var cache: [URL: Status] = [:]
  private var cacheById: [String: Status] = [:]

  public var badStatusesURLs = Set<URL>()

  private init() {}

  public func set(url: URL, status: Status) {
    cache[url] = status
  }

  public func set(id: String, status: Status) {
    cacheById[id] = status
  }

  public func get(url: URL) -> Status? {
    cache[url]
  }

  public func get(id: String) -> Status? {
    cacheById[id]
  }
}
