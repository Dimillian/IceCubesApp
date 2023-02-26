import Foundation
import Models
import SwiftUI

@MainActor
class StatusEmbedCache {
  static let shared = StatusEmbedCache()

  private var cache: [URL: Status] = [:]

  private init() {}

  func set(url: URL, status: Status) {
    cache[url] = status
  }

  func get(url: URL) -> Status? {
    cache[url]
  }
}
