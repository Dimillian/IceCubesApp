import Foundation
import Models
import SwiftUI

@MainActor
public class StatusEmbedCache {
  public static let shared = StatusEmbedCache()

  private var cache: [URL: Status] = [:]

  public var badStatusesURLs = Set<URL>()

  private init() {}

  public func set(url: URL, status: Status) {
    cache[url] = status
  }

  public func get(url: URL) -> Status? {
    cache[url]
  }
}
