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
    let showReplies = await contentFilter.showReplies
    let showBoosts = await contentFilter.showBoosts
    let showThreads = await contentFilter.showThreads
    let showQuotePosts = await contentFilter.showQuotePosts
    return items.compactMap { item in
      guard case .status(let status) = item else { return nil }
      if status.isHidden
        || !showReplies && status.inReplyToId != nil
          && status.inReplyToAccountId != status.account.id
        || !showBoosts && status.reblog != nil
        || !showThreads && status.inReplyToAccountId == status.account.id
        || !showQuotePosts && !status.content.statusesURLs.isEmpty
      {
        return nil
      }
      return status
    }
  }
  
  func getFilteredItems() async -> [TimelineItem] {
    let contentFilter = await TimelineContentFilter.shared
    let showReplies = await contentFilter.showReplies
    let showBoosts = await contentFilter.showBoosts
    let showThreads = await contentFilter.showThreads
    let showQuotePosts = await contentFilter.showQuotePosts
    return items.filter { item in
      switch item {
      case .gap:
        return true
      case .status(let status):
        if status.isHidden
          || !showReplies && status.inReplyToId != nil
            && status.inReplyToAccountId != status.account.id
          || !showBoosts && status.reblog != nil
          || !showThreads && status.inReplyToAccountId == status.account.id
          || !showQuotePosts && !status.content.statusesURLs.isEmpty
        {
          return false
        }
        return true
      }
    }
  }

  func count() -> Int {
    items.count
  }

  func reset() {
    items = []
  }

  func indexOf(statusId: String) -> Int? {
    items.firstIndex(where: { item in
      if case .status(let status) = item {
        return status.id == statusId
      }
      return false
    })
  }

  func contains(statusId: String) -> Bool {
    items.contains(where: { item in
      if case .status(let status) = item {
        return status.id == statusId
      }
      return false
    })
  }

  func set(_ statuses: [Status]) {
    self.items = statuses.map { .status($0) }
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
  
  func insertGap(_ gap: TimelineGap, at index: Int) {
    items.insert(.gap(gap), at: index)
  }
  
  func replaceGap(id: String, with statuses: [Status]) {
    if let gapIndex = items.firstIndex(where: { item in
      if case .gap(let gap) = item {
        return gap.id == id
      }
      return false
    }) {
      items.remove(at: gapIndex)
      items.insert(contentsOf: statuses.map { .status($0) }, at: gapIndex)
    }
  }
  
  func updateGapLoadingState(id: String, isLoading: Bool) {
    if let gapIndex = items.firstIndex(where: { item in
      if case .gap(let gap) = item {
        return gap.id == id
      }
      return false
    }) {
      if case .gap(var gap) = items[gapIndex] {
        gap.isLoading = isLoading
        items[gapIndex] = .gap(gap)
      }
    }
  }

  func remove(after status: Status, safeOffset: Int) {
    if let index = items.firstIndex(where: { item in
      if case .status(let s) = item {
        return s.id == status.id
      }
      return false
    }) {
      let safeIndex = index + safeOffset
      if items.count > safeIndex {
        items.removeSubrange(safeIndex..<items.endIndex)
      }
    }
  }

  func replace(_ status: Status, at index: Int) {
    items[index] = .status(status)
  }

  func remove(_ statusId: String) -> Status? {
    if let index = items.firstIndex(where: { item in
      if case .status(let status) = item {
        return status.id == statusId
      }
      return false
    }) {
      if case .status(let status) = items.remove(at: index) {
        return status
      }
    }
    return nil
  }
}
