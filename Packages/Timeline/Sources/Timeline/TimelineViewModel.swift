import Env
import Models
import Network
import Status
import SwiftUI

@MainActor
class TimelineViewModel: ObservableObject {
  var client: Client? {
    didSet {
      if oldValue != client {
        statuses = []
      }
    }
  }

  // Internal source of truth for a timeline.
  private var statuses: [Status] = []
  private var visibileStatusesIds = Set<String>()
  var scrollToTopVisible: Bool = false {
    didSet {
      if scrollToTopVisible {
        pendingStatusesObserver.pendingStatuses = []
      }
    }
  }

  private var canStreamEvents: Bool = true

  let pendingStatusesObserver: PendingStatusesObserver = .init()

  private var accountId: String? {
    CurrentAccount.shared.account?.id
  }

  private let cache: TimelineCache = .shared

  @Published var scrollToIndex: Int?

  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .federated {
    didSet {
      Task {
        if oldValue != timeline {
          statuses = []
          pendingStatusesObserver.pendingStatuses = []
          tag = nil
        }
        await fetchStatuses()
        switch timeline {
        case let .hashtag(tag, _):
          await fetchTag(id: tag)
        default:
          break
        }
      }
    }
  }

  @Published var tag: Tag?

  var pendingStatusesEnabled: Bool {
    timeline == .home
  }

  var serverName: String {
    client?.server ?? "Error"
  }

  private func fetchTag(id: String) async {
    guard let client else { return }
    do {
      tag = try await client.get(endpoint: Tags.tag(id: id))
    } catch {}
  }

  func handleEvent(event: any StreamEvent, currentAccount _: CurrentAccount) {
    if let event = event as? StreamEventUpdate,
       canStreamEvents,
       pendingStatusesEnabled,
       !statuses.contains(where: { $0.id == event.status.id })
    {
      pendingStatusesObserver.pendingStatuses.insert(event.status.id, at: 0)
      var newStatus = event.status
      if let accountId {
        if newStatus.mentions.first(where: { $0.id == accountId }) != nil {
          newStatus.uiShouldHighlight = true
        }
      }
      statuses.insert(newStatus, at: 0)
      Task {
        await cacheHome()
      }
      withAnimation {
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    } else if let event = event as? StreamEventDelete {
      withAnimation {
        statuses.removeAll(where: { $0.id == event.status })
        Task {
          await cacheHome()
        }
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    } else if let event = event as? StreamEventStatusUpdate {
      if let originalIndex = statuses.firstIndex(where: { $0.id == event.status.id }) {
        statuses[originalIndex] = event.status
        Task {
          await cacheHome()
        }
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    }
  }
}

// MARK: - Cache

extension TimelineViewModel {
  private func cacheHome() async {
    if let client, timeline == .home {
      await cache.set(statuses: statuses, client: client)
    }
  }

  private func getCachedStatuses() async -> [Status]? {
    if let client {
      return await cache.getStatuses(for: client)
    }
    return nil
  }
}

// MARK: - StatusesFetcher

extension TimelineViewModel: StatusesFetcher {
  func fetchStatuses() async {
    guard let client else { return }
    do {
      if statuses.isEmpty {
        try await fetchFirstPage(client: client)
      } else if let latest = statuses.first {
        try await fetchNewPagesFrom(latestStatus: latest, client: client)
      }
    } catch {
      statusesState = .error(error: error)
      canStreamEvents = true
      print("timeline parse error: \(error)")
    }
  }

  // Hydrate statuses in the Timeline when statuses are empty.
  private func fetchFirstPage(client: Client) async throws {
    pendingStatusesObserver.pendingStatuses = []
    statusesState = .loading

    // If we get statuses from the cache for the home timeline, we displays those.
    // Else we fetch top most page from the API.
    if let cachedStatuses = await getCachedStatuses(), timeline == .home {
      statuses = cachedStatuses
      withAnimation {
        statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
      }
      // And then we fetch statuses again toget newest statuses from there.
      await fetchStatuses()
    } else {
      statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                  maxId: nil,
                                                                  minId: nil,
                                                                  offset: statuses.count))

      updateMentionsToBeHighlighted(&statuses)
      ReblogCache.shared.removeDuplicateReblogs(&statuses)

      await cacheHome()
      withAnimation {
        statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
      }
    }
  }

  // Fetch pages from the top most status of the tomeline.
  private func fetchNewPagesFrom(latestStatus: Status, client _: Client) async throws {
    canStreamEvents = false
    var newStatuses: [Status] = await fetchNewPages(minId: latestStatus.id, maxPages: 10)

    // Dedup statuses, a status with the same id could have been streamed in.
    newStatuses = newStatuses.filter { status in
      !statuses.contains(where: { $0.id == status.id })
    }
    
    ReblogCache.shared.removeDuplicateReblogs(&newStatuses)


    // If no new statuses, resume streaming and exit.
    guard !newStatuses.isEmpty else {
      canStreamEvents = true
      return
    }

    // Keep track of the top most status, so we can scroll back to it after view update.
    let topStatusId = statuses.first?.id

    // Insert new statuses in internal datasource.
    statuses.insert(contentsOf: newStatuses, at: 0)

    // Cache statuses for home timeline.
    await cacheHome()

    // If pending statuses are not enabled, we simply load status on the top regardless of the current position.
    if !pendingStatusesEnabled {
      pendingStatusesObserver.pendingStatuses = []
      withAnimation {
        statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
        canStreamEvents = true
      }
    } else {
      // Append new statuses in the timeline indicator.
      pendingStatusesObserver.pendingStatuses.insert(contentsOf: newStatuses.map { $0.id }, at: 0)

      // High chance the user is scrolled to the top.
      // We need to update the statuses state, and then scroll to the previous top most status.
      if let topStatusId, visibileStatusesIds.contains(topStatusId), scrollToTopVisible {
        pendingStatusesObserver.disableUpdate = true
        statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
        scrollToIndex = newStatuses.count + 1
        DispatchQueue.main.async {
          self.pendingStatusesObserver.disableUpdate = false
          self.canStreamEvents = true
        }
      } else {
        // This will keep the scroll position (if the list is scrolled) and prepend statuses on the top.
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
          canStreamEvents = true
        }
      }
    }
  }

  private func fetchNewPages(minId: String, maxPages: Int) async -> [Status] {
    guard let client else { return [] }
    var pagesLoaded = 0
    var allStatuses: [Status] = []
    var latestMinId = minId
    do {
      while var newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                         maxId: nil,
                                                                                         minId: latestMinId,
                                                                                         offset: statuses.count)),
        !newStatuses.isEmpty,
        pagesLoaded < maxPages
      {
        pagesLoaded += 1

        updateMentionsToBeHighlighted(&newStatuses)
        ReblogCache.shared.removeDuplicateReblogs(&newStatuses)
        
        allStatuses.insert(contentsOf: newStatuses, at: 0)
        latestMinId = newStatuses.first?.id ?? ""
      }
    } catch {
      return allStatuses
    }
    return allStatuses
  }

  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = statuses.last?.id else { return }
      statusesState = .display(statuses: statuses, nextPageState: .loadingNextPage)
      var newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                   maxId: lastId,
                                                                                   minId: nil,
                                                                                   offset: statuses.count))


      updateMentionsToBeHighlighted(&newStatuses)
      ReblogCache.shared.removeDuplicateReblogs(&newStatuses)

      statuses.append(contentsOf: newStatuses)

      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }

  private func updateMentionsToBeHighlighted(_ statuses: inout [Status]) {
    if !statuses.isEmpty, let accountId {
      for i in statuses.indices {
        if statuses[i].mentions.first(where: { $0.id == accountId }) != nil {
          statuses[i].uiShouldHighlight = true
        }
      }
    }
  }

  func statusDidAppear(status: Status) {
    pendingStatusesObserver.removeStatus(status: status)
    visibileStatusesIds.insert(status.id)
  }

  func statusDidDisappear(status: Status) {
    visibileStatusesIds.remove(status.id)
  }
}
