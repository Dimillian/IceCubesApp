import Env
import Models
import Network
import Observation
import Status
import SwiftUI

@MainActor
@Observable class TimelineViewModel {
  var scrollToIndex: Int?
  var statusesState: StatusesState = .loading
  var timeline: TimelineFilter = .federated {
    didSet {
      timelineTask?.cancel()
      timelineTask = Task {
        if timeline == .latest {
          if oldValue == .home {
            await clearHomeCache()
          }
          timeline = oldValue
        }
        if oldValue != timeline {
          await reset()
          pendingStatusesObserver.pendingStatuses = []
          tag = nil
        }
        guard !Task.isCancelled else {
          return
        }
        await fetchNewestStatuses()
        switch timeline {
        case let .hashtag(tag, _):
          await fetchTag(id: tag)
        default:
          break
        }
      }
    }
  }

  private var timelineTask: Task<Void, Never>?

  var tag: Tag?

  // Internal source of truth for a timeline.
  private var datasource = TimelineDatasource()
  private let cache = TimelineCache()
  private var visibileStatusesIds = Set<String>()
  private var canStreamEvents: Bool = true

  private var accountId: String? {
    CurrentAccount.shared.account?.id
  }

  var client: Client? {
    didSet {
      if oldValue != client {
        Task {
          await reset()
        }
      }
    }
  }

  var scrollToTopVisible: Bool = false {
    didSet {
      if scrollToTopVisible {
        pendingStatusesObserver.pendingStatuses = []
      }
    }
  }

  var serverName: String {
    client?.server ?? "Error"
  }

  var isTimelineVisible: Bool = false
  let pendingStatusesObserver: PendingStatusesObserver = .init()
  var scrollToIndexAnimated: Bool = false

  init() {
    pendingStatusesObserver.scrollToIndex = { [weak self] index in
      self?.scrollToIndexAnimated = true
      self?.scrollToIndex = index
    }
  }

  private func fetchTag(id: String) async {
    guard let client else { return }
    do {
      tag = try await client.get(endpoint: Tags.tag(id: id))
    } catch {}
  }

  func reset() async {
    await datasource.reset()
  }

  func handleEvent(event: any StreamEvent, currentAccount _: CurrentAccount) {
    Task {
      if let event = event as? StreamEventUpdate,
         timeline == .home,
         canStreamEvents,
         isTimelineVisible,
         await !datasource.contains(statusId: event.status.id)
      {
        pendingStatusesObserver.pendingStatuses.insert(event.status.id, at: 0)
        let newStatus = event.status
        await datasource.insert(newStatus, at: 0)
        await cacheHome()
        let statuses = await datasource.get()
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        }
      } else if let event = event as? StreamEventDelete {
        await datasource.remove(event.status)
        await cacheHome()
        let statuses = await datasource.get()
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        }
      } else if let event = event as? StreamEventStatusUpdate {
        if let originalIndex = await datasource.indexOf(statusId: event.status.id) {
          await datasource.replace(event.status, at: originalIndex)
          await cacheHome()
          statusesState = await .display(statuses: datasource.get(), nextPageState: .hasNextPage)
        }
      }
    }
  }
}

// MARK: - Cache

extension TimelineViewModel {
  private func cacheHome() async {
    if let client, timeline == .home {
      await cache.set(statuses: datasource.get(), client: client.id)
    }
  }

  private func getCachedStatuses() async -> [Status]? {
    if let client {
      return await cache.getStatuses(for: client.id)
    }
    return nil
  }

  private func clearHomeCache() async {
    if let client {
      await cache.clearCache(for: client.id)
      await cache.setLatestSeenStatuses(ids: [], for: client)
    }
  }
}

// MARK: - StatusesFetcher

extension TimelineViewModel: StatusesFetcher {
  func pullToRefresh() async {
    timelineTask?.cancel()
    if !timeline.supportNewestPagination || UserPreferences.shared.fastRefreshEnabled {
      await reset()
    }
    await fetchNewestStatuses()
  }

  func refreshTimeline() {
    timelineTask?.cancel()
    timelineTask = Task {
      if UserPreferences.shared.fastRefreshEnabled {
        await reset()
      }
      await fetchNewestStatuses()
    }
  }

  func fetchNewestStatuses() async {
    guard let client else { return }
    do {
      if await datasource.isEmpty {
        try await fetchFirstPage(client: client)
      } else if let latest = await datasource.get().first, timeline.supportNewestPagination {
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

    if await datasource.isEmpty {
      statusesState = .loading
    }

    // If we get statuses from the cache for the home timeline, we displays those.
    // Else we fetch top most page from the API.
    if let cachedStatuses = await getCachedStatuses(),
       !cachedStatuses.isEmpty,
       timeline == .home, !UserPreferences.shared.fastRefreshEnabled
    {
      await datasource.set(cachedStatuses)
      if let latestSeenId = await cache.getLatestSeenStatus(for: client)?.last,
         let index = await datasource.indexOf(statusId: latestSeenId),
         index > 0
      {
        // Restore cache and scroll to latest seen status.
        statusesState = await .display(statuses: datasource.get(), nextPageState: .hasNextPage)
        scrollToIndexAnimated = false
        scrollToIndex = index + 1
      } else {
        // Restore cache and scroll to top.
        let statuses = await datasource.get()
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        }
      }
      // And then we fetch statuses again toget newest statuses from there.
      await fetchNewestStatuses()
    } else {
      var statuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                maxId: nil,
                                                                                minId: nil,
                                                                                offset: 0))

      ReblogCache.shared.removeDuplicateReblogs(&statuses)
      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)

      await datasource.set(statuses)
      await cacheHome()

      withAnimation {
        statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
      }
    }
  }

  // Fetch pages from the top most status of the tomeline.
  private func fetchNewPagesFrom(latestStatus: Status, client: Client) async throws {
    canStreamEvents = false
    let initialTimeline = timeline
    var newStatuses: [Status] = await fetchNewPages(minId: latestStatus.id, maxPages: 10)

    // Dedup statuses, a status with the same id could have been streamed in.
    let ids = await datasource.get().map(\.id)
    newStatuses = newStatuses.filter { status in
      !ids.contains(where: { $0 == status.id })
    }

    ReblogCache.shared.removeDuplicateReblogs(&newStatuses)
    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)

    // If no new statuses, resume streaming and exit.
    guard !newStatuses.isEmpty else {
      canStreamEvents = true
      return
    }

    // If the timeline is not visible, we don't update it as it would mess up the user position.
    guard isTimelineVisible else {
      canStreamEvents = true
      return
    }

    // Return if task has been cancelled.
    guard !Task.isCancelled else {
      canStreamEvents = true
      return
    }

    // As this is a long runnign task we need to ensure that the user didn't changed the timeline filter.
    guard initialTimeline == timeline else {
      canStreamEvents = true
      return
    }

    // Keep track of the top most status, so we can scroll back to it after view update.
    let topStatusId = await datasource.get().first?.id

    // Insert new statuses in internal datasource.
    await datasource.insert(contentOf: newStatuses, at: 0)

    // Cache statuses for home timeline.
    await cacheHome()

    // Append new statuses in the timeline indicator.
    pendingStatusesObserver.pendingStatuses.insert(contentsOf: newStatuses.map(\.id), at: 0)

    // High chance the user is scrolled to the top.
    // We need to update the statuses state, and then scroll to the previous top most status.
    if let topStatusId, visibileStatusesIds.contains(topStatusId), scrollToTopVisible {
      pendingStatusesObserver.disableUpdate = true
      let statuses = await datasource.get()
      statusesState = .display(statuses: statuses,
                               nextPageState: statuses.count < 20 ? .none : .hasNextPage)
      scrollToIndexAnimated = false
      scrollToIndex = newStatuses.count + 1
      DispatchQueue.main.async {
        self.pendingStatusesObserver.disableUpdate = false
        self.canStreamEvents = true
      }
    } else {
      // This will keep the scroll position (if the list is scrolled) and prepend statuses on the top.
      let statuses = await datasource.get()
      withAnimation {
        statusesState = .display(statuses: statuses,
                                 nextPageState: statuses.count < 20 ? .none : .hasNextPage)
        canStreamEvents = true
      }
    }

    // We trigger a new fetch so we can get the next new statuses if any.
    // If none, it'll stop there.
    // Only do that in the context of the home timeline as other don't worth catching up that much.
    if timeline == .home,
       !Task.isCancelled,
       let latest = await datasource.get().first
    {
      try await fetchNewPagesFrom(latestStatus: latest, client: client)
    }
  }

  private func fetchNewPages(minId: String, maxPages: Int) async -> [Status] {
    guard let client else { return [] }
    var pagesLoaded = 0
    var allStatuses: [Status] = []
    var latestMinId = minId
    do {
      while
        !Task.isCancelled,
        var newStatuses: [Status] =
        try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                         maxId: nil,
                                                         minId: latestMinId,
                                                         offset: datasource.get().count)),
        !newStatuses.isEmpty,
        pagesLoaded < maxPages
      {
        pagesLoaded += 1

        ReblogCache.shared.removeDuplicateReblogs(&newStatuses)
        StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)

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
      guard let lastId = await datasource.get().last?.id else { return }
      statusesState = await .display(statuses: datasource.get(), nextPageState: .loadingNextPage)
      var newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                   maxId: lastId,
                                                                                   minId: nil,
                                                                                   offset: datasource.get().count))

      ReblogCache.shared.removeDuplicateReblogs(&newStatuses)

      await datasource.append(contentOf: newStatuses)
      StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)

      statusesState = await .display(statuses: datasource.get(),
                                     nextPageState: newStatuses.count < 20 ? .none : .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }

  func statusDidAppear(status: Status) {
    pendingStatusesObserver.removeStatus(status: status)
    visibileStatusesIds.insert(status.id)

    if let client, timeline == .home {
      Task {
        await cache.setLatestSeenStatuses(ids: visibileStatusesIds.map { $0 }, for: client)
      }
    }
  }

  func statusDidDisappear(status: Status) {
    visibileStatusesIds.remove(status.id)
  }
}
