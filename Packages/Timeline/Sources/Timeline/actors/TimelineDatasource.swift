import Env
import Foundation
import Models

actor TimelineDatasource {
  private var items: [TimelineItem] = []

  var isEmpty: Bool {
    items.isEmpty
  }

  func get() -> [Status] {
    items.compactMap { item in
      if case .status(let status) = item {
        return status
      }
      return nil
    }
  }

  func getItems() -> [TimelineItem] {
    items
  }

  func getFiltered() async -> [Status] {
    let contentFilter = await TimelineContentFilter.shared
    var filtered: [Status] = []
    for item in items {
      guard case .status(let status) = item else { continue }
      if await shouldShowStatus(status, filter: contentFilter) {
        filtered.append(status)
      }
    }
    return filtered
  }

  func getFilteredItems() async -> [TimelineItem] {
    let contentFilter = await TimelineContentFilter.shared
    var filtered: [TimelineItem] = []
    for item in items {
      switch item {
      case .gap:
        filtered.append(item)
      case .status(let status):
        if await shouldShowStatus(status, filter: contentFilter) {
          filtered.append(item)
        }
      }
    }
    return filtered
  }

  func count() -> Int {
    items.count
  }

  func reset() {
    items = []
  }

  // MARK: - Status Finding Helpers

  private func findStatusIndex(id: String) -> Int? {
    items.firstIndex(where: { item in
      if case .status(let status) = item {
        return status.id == id
      }
      return false
    })
  }

  private func findGapIndex(id: String) -> Int? {
    items.firstIndex(where: { item in
      if case .gap(let gap) = item {
        return gap.id == id
      }
      return false
    })
  }

  // MARK: - Status Operations

  func indexOf(statusId: String) -> Int? {
    findStatusIndex(id: statusId)
  }

  func contains(statusId: String) -> Bool {
    findStatusIndex(id: statusId) != nil
  }

  func set(_ statuses: [Status]) {
    self.items = statuses.map { .status($0) }
  }

  func setItems(_ items: [TimelineItem]) {
    self.items = items
  }

  func append(_ status: Status) {
    items.append(.status(status))
  }

  func append(contentOf statuses: [Status]) {
    items.append(contentsOf: statuses.map { .status($0) })
  }

  func insert(_ status: Status, at index: Int) {
    items.insert(.status(status), at: index)
  }

  func insert(contentOf statuses: [Status], at index: Int) {
    items.insert(contentsOf: statuses.map { .status($0) }, at: index)
  }

  func remove(after status: Status, safeOffset: Int) {
    guard let index = findStatusIndex(id: status.id) else { return }
    let safeIndex = index + safeOffset
    if items.count > safeIndex {
      items.removeSubrange(safeIndex..<items.endIndex)
    }
  }

  func replace(_ status: Status, at index: Int) {
    items[index] = .status(status)
  }

  func remove(_ statusId: String) -> Status? {
    guard let index = findStatusIndex(id: statusId),
      case .status(let status) = items.remove(at: index)
    else {
      return nil
    }
    return status
  }

  // MARK: - Gap Operations

  func insertGap(_ gap: TimelineGap, at index: Int) {
    items.insert(.gap(gap), at: index)
  }

  func replaceGap(id: String, with statuses: [Status]) {
    guard let gapIndex = findGapIndex(id: id) else { return }
    items.remove(at: gapIndex)
    items.insert(contentsOf: statuses.map { .status($0) }, at: gapIndex)
  }

  func updateGapLoadingState(id: String, isLoading: Bool) {
    guard let gapIndex = findGapIndex(id: id),
      case .gap(var gap) = items[gapIndex]
    else { return }
    gap.isLoading = isLoading
    items[gapIndex] = .gap(gap)
  }

  // MARK: - Private Helpers

  private func shouldShowStatus(_ status: Status, filter: TimelineContentFilter) async -> Bool {
    let showReplies = await filter.showReplies
    let showBoosts = await filter.showBoosts
    let showThreads = await filter.showThreads
    let showQuotePosts = await filter.showQuotePosts

    return !status.isHidden
      && (showReplies || status.inReplyToId == nil
        || status.inReplyToAccountId == status.account.id)
      && (showBoosts || status.reblog == nil)
      && (showThreads || status.inReplyToAccountId != status.account.id)
      && (showQuotePosts || status.content.statusesURLs.isEmpty)
  }
}
