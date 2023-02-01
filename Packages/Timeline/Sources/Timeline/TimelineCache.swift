import Models
import Network
import SwiftUI

actor TimelineCache {
  static let shared: TimelineCache = .init()

  private var memoryCache: [Client: [Status]] = [:]

  private init() {}

  func set(statuses: [Status], client: Client) {
    memoryCache[client] = statuses.prefix(upTo: min(100, statuses.count - 1)).map { $0 }
  }

  func getStatuses(for client: Client) -> [Status]? {
    memoryCache[client]
  }
}
