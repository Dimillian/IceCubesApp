import Env
import Models
import NetworkClient
import Observation
import StatusKit
import SwiftUI

@MainActor
@Observable class TimelineViewModel {
  var scrollToId: String?
  var statusesState: StatusesState = .loading
  var timeline: TimelineFilter = .home {
    willSet {
      if timeline == .home,
        newValue != .resume,
        newValue != timeline
      {
        saveMarker()
      }
    }
    didSet {
      timelineTask?.cancel()
      timelineTask = Task {
        await handleLatestOrResume(oldValue)

        if oldValue != timeline {
          Telemetry.signal(
            "timeline.filter.updated",
            parameters: ["timeline": timeline.rawValue])

          await reset()
          pendingStatusesObserver.pendingStatuses = []
          tag = nil
        }

        guard !Task.isCancelled else {
          return
        }

        await fetchNewestStatuses(pullToRefresh: false)
        switch timeline {
        case let .hashtag(tag, _):
          await fetchTag(id: tag)
        default:
          break
        }
      }
    }
  }

  private(set) var timelineTask: Task<Void, Never>?

  var tag: Tag?

  // Internal source of truth for a timeline.
  @ObservationIgnored
  private(set) var datasource = TimelineDatasource()
  private let statusFetcher: TimelineStatusFetching

  @ObservationIgnored
  private let cache = TimelineCache()

  private var isCacheEnabled: Bool {
    canFilterTimeline && timeline.supportNewestPagination && client?.isAuth == true
  }

  @ObservationIgnored
  private var visibleStatuses: [Status] = []

  private var canStreamEvents: Bool = true {
    didSet {
      if canStreamEvents {
        pendingStatusesObserver.isLoadingNewStatuses = false
      }
    }
  }

  @ObservationIgnored
  var canFilterTimeline: Bool = true

  var client: MastodonClient? {
    didSet {
      if oldValue != client {
        Task {
          await reset()
        }
      }
    }
  }

  var scrollToTopVisible: Bool = false

  var serverName: String {
    client?.server ?? "Error"
  }

  let pendingStatusesObserver: TimelineUnreadStatusesObserver = .init()
  var marker: Marker.Content?

  init(statusFetcher: TimelineStatusFetching = TimelineStatusFetcher()) {
    self.statusFetcher = statusFetcher
  }

  private func fetchTag(id: String) async {
    guard let client else { return }
    do {
      let tag: Tag = try await client.get(endpoint: Tags.tag(id: id))
      withAnimation {
        self.tag = tag
      }
    } catch {}
  }

  func reset() async {
    await datasource.reset()
  }

  private func handleLatestOrResume(_ oldValue: TimelineFilter) async {
    if timeline == .latest || timeline == .resume {
      await clearCache(filter: oldValue)
      if timeline == .resume, let marker = await fetchMarker() {
        self.marker = marker
      }
      timeline = oldValue
    }
  }
}

// MARK: - Cache

extension TimelineViewModel {
  private func cache() async {
    if let client, isCacheEnabled {
      await cache.set(statuses: datasource.get(), client: client.id, filter: timeline.id)
    }
  }

  private func getCachedStatuses() async -> [Status]? {
    if let client, isCacheEnabled {
      return await cache.getStatuses(for: client.id, filter: timeline.id)
    }
    return nil
  }

  private func clearCache(filter: TimelineFilter) async {
    if let client, isCacheEnabled {
      await cache.clearCache(for: client.id, filter: filter.id)
      await cache.setLatestSeenStatuses([], for: client, filter: filter.id)
    }
  }
}

// MARK: - StatusesFetcher

extension TimelineViewModel: GapLoadingFetcher {
  func pullToRefresh() async {
    timelineTask?.cancel()

    if !timeline.supportNewestPagination {
      await reset()
    }
    await fetchNewestStatuses(pullToRefresh: true)
  }

  func refreshTimeline() {
    timelineTask?.cancel()
    timelineTask = Task {
      await fetchNewestStatuses(pullToRefresh: false)
    }
  }

  func refreshTimelineContentFilter() async {
    timelineTask?.cancel()
    await updateStatusesState()
  }

  func fetchStatuses(from: Marker.Content) async throws {
    guard let client else { return }
    statusesState = .loading
    let statuses: [Status] = try await client.get(
      endpoint: timeline.endpoint(
        sinceId: nil,
        maxId: from.lastReadId,
        minId: nil,
        offset: 0,
        limit: 40))

    await updateDatasourceAndState(statuses: statuses, client: client, replaceExisting: true)
    marker = nil
    await fetchNewestStatuses(pullToRefresh: false)
  }

  func fetchNewestStatuses(pullToRefresh: Bool) async {
    guard let client else { return }
    do {
      if let marker {
        try await fetchStatuses(from: marker)
      } else if await datasource.isEmpty {
        try await fetchFirstPage(client: client)
      } else if let latest = await datasource.get().first, timeline.supportNewestPagination {
        pendingStatusesObserver.isLoadingNewStatuses = !pullToRefresh
        try await fetchNewPagesFrom(latestStatus: latest.id, client: client)
      }
    } catch {
      if await datasource.isEmpty {
        statusesState = .error(error: .noData)
      }
      canStreamEvents = true
    }
  }

  // Hydrate statuses in the Timeline when statuses are empty.
  private func fetchFirstPage(client: MastodonClient) async throws {
    pendingStatusesObserver.pendingStatuses = []

    let datasourceIsEmpty = await datasource.isEmpty
    if datasourceIsEmpty {
      statusesState = .loading
    }

    // If we get statuses from the cache for the home timeline, we displays those.
    // Else we fetch top most page from the API.
    if timeline.supportNewestPagination,
      let cachedStatuses = await getCachedStatuses(),
      !cachedStatuses.isEmpty
    {
      await datasource.set(cachedStatuses)
      let items = await datasource.getFilteredItems()
      if let latestSeenId = await cache.getLatestSeenStatus(for: client, filter: timeline.id)?.first
      {
        // Restore cache and scroll to latest seen status.
        scrollToId = latestSeenId
        statusesState = .displayWithGaps(items: items, nextPageState: .hasNextPage)
      } else {
        // Restore cache and scroll to top.
        withAnimation {
          statusesState = .displayWithGaps(items: items, nextPageState: .hasNextPage)
        }
      }
      // And then we fetch statuses again to get newest statuses from there.
      await fetchNewestStatuses(pullToRefresh: false)
    } else {
      let statuses: [Status] = try await statusFetcher.fetchFirstPage(
        client: client,
        timeline: timeline)

      await updateDatasourceAndState(statuses: statuses, client: client, replaceExisting: true)

      // If we got 40 or more statuses, there might be older ones - create a gap
      if statuses.count >= 40, let oldestStatus = statuses.last, !datasourceIsEmpty {
        await createGapForOlderStatuses(maxId: oldestStatus.id, at: statuses.count)
      }
    }
  }

  // Fetch pages from the top most status of the timeline.
  private func fetchNewPagesFrom(latestStatus: String, client: MastodonClient) async throws {
    canStreamEvents = false
    let initialTimeline = timeline

    // First, fetch the absolute newest statuses (no ID parameters)
    let newestStatuses: [Status] = try await statusFetcher.fetchFirstPage(
      client: client,
      timeline: timeline)

    guard !newestStatuses.isEmpty,
      !Task.isCancelled,
      initialTimeline == timeline
    else {
      canStreamEvents = true
      return
    }

    let currentIds = await datasource.get().map(\.id)
    let actuallyNewStatuses = newestStatuses.filter { status in
      !currentIds.contains(where: { $0 == status.id }) && status.id > latestStatus
    }

    guard !actuallyNewStatuses.isEmpty else {
      canStreamEvents = true
      return
    }

    StatusDataControllerProvider.shared.updateDataControllers(
      for: actuallyNewStatuses, client: client)

    // Pass the original count to determine if we need a gap
    await updateTimelineWithNewStatuses(
      actuallyNewStatuses,
      latestStatus: latestStatus,
      fetchedCount: newestStatuses.count
    )
    canStreamEvents = true
  }

  private func updateTimelineWithNewStatuses(
    _ newStatuses: [Status], latestStatus: String, fetchedCount: Int
  ) async {
    let topStatus = await datasource.getFiltered().first

    // Insert new statuses at the top
    await datasource.insert(contentOf: newStatuses, at: 0)

    // Only create a gap if:
    // 1. We fetched a full page (suggesting there might be more)
    // 2. AND we have a significant number of actually new statuses
    if fetchedCount >= 40 && newStatuses.count >= 40, let oldestNewStatus = newStatuses.last {
      // Create a gap to load statuses between the oldest new status and our previous top
      let gap = TimelineGap(sinceId: latestStatus, maxId: oldestNewStatus.id, direction: .downward)
      // Insert the gap after all the new statuses
      await datasource.insertGap(gap, at: newStatuses.count)
    }

    if let lastVisible = visibleStatuses.last {
      await datasource.remove(after: lastVisible, safeOffset: 15)
    }
    await cache()
    pendingStatusesObserver.pendingStatuses.insert(contentsOf: newStatuses.map(\.id), at: 0)

    let items = await datasource.getFilteredItems()

    if let topStatus = topStatus,
      visibleStatuses.contains(where: { $0.id == topStatus.id }),
      scrollToTopVisible
    {
      scrollToId = topStatus.id
      statusesState = .displayWithGaps(items: items, nextPageState: .hasNextPage)
    } else {
      withAnimation {
        statusesState = .displayWithGaps(items: items, nextPageState: .hasNextPage)
      }
    }
  }

  enum NextPageError: Error {
    case internalError
  }

  func fetchNextPage() async throws {
    let statuses = await datasource.get()
    guard let client, let lastId = statuses.last?.id else { throw NextPageError.internalError }
    let newStatuses: [Status] = try await statusFetcher.fetchNextPage(
      client: client,
      timeline: timeline,
      lastId: lastId,
      offset: statuses.count)

    await datasource.append(contentOf: newStatuses)
    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)

    statusesState = await .displayWithGaps(
      items: datasource.getFilteredItems(),
      nextPageState: newStatuses.count < 20 ? .none : .hasNextPage)
  }

  func statusDidAppear(status: Status) {
    pendingStatusesObserver.removeStatus(status: status)
    visibleStatuses.insert(status, at: 0)

    if let client, timeline.supportNewestPagination {
      Task {
        await cache.setLatestSeenStatuses(visibleStatuses, for: client, filter: timeline.id)
      }
    }
  }

  func statusDidDisappear(status: Status) {
    visibleStatuses.removeAll(where: { $0.id == status.id })
  }

  func loadGap(gap: TimelineGap) async {
    guard let client else { return }

    // Update gap loading state
    await datasource.updateGapLoadingState(id: gap.id, isLoading: true)

    // Update UI to show loading state without causing jumps
    await updateStatusesState()

    do {
      // Fetch statuses within the gap
      let statuses: [Status] = try await client.get(
        endpoint: timeline.endpoint(
          sinceId: gap.sinceId.isEmpty ? nil : gap.sinceId,
          maxId: gap.maxId,
          minId: nil,
          offset: 0,
          limit: 50))

      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)

      // Get the original gap index before replacing
      let items = await datasource.getItems()
      let gapIndex = items.firstIndex(where: { item in
        if case .gap(let g) = item {
          return g.id == gap.id
        }
        return false
      })

      // Replace the gap with the fetched statuses
      await datasource.replaceGap(id: gap.id, with: statuses)

      // If we fetched 40 or more statuses, there might be more older statuses
      // Lower threshold because some instances might not return exactly 50
      if statuses.count >= 40, let oldestLoadedStatus = statuses.last,
        let originalGapIndex = gapIndex
      {
        // Create a new gap from the original gap's sinceId to the oldest status we just loaded
        await createGapForOlderStatuses(
          sinceId: gap.sinceId.isEmpty ? nil : gap.sinceId,
          maxId: oldestLoadedStatus.id,
          at: originalGapIndex + statuses.count
        )
      }

      // Update the display
      await updateStatusesStateWithAnimation()
    } catch {
      // If loading fails, reset the gap loading state
      await datasource.updateGapLoadingState(id: gap.id, isLoading: false)
      await refreshTimelineContentFilter()
    }
  }

  // MARK: - Helper Methods

  private func updateDatasourceAndState(statuses: [Status], client: MastodonClient, replaceExisting: Bool)
    async
  {
    StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)

    if replaceExisting {
      await datasource.set(statuses)
    } else {
      await datasource.append(contentOf: statuses)
    }

    await cache()
    await updateStatusesStateWithAnimation()
  }

  private func updateStatusesState() async {
    let items = await datasource.getFilteredItems()
    statusesState = .displayWithGaps(items: items, nextPageState: .hasNextPage)
  }

  private func updateStatusesStateWithAnimation() async {
    let items = await datasource.getFilteredItems()
    withAnimation {
      statusesState = .displayWithGaps(items: items, nextPageState: .hasNextPage)
    }
  }

  private func createGapForOlderStatuses(sinceId: String? = nil, maxId: String, at index: Int) async {
    let gap = TimelineGap(sinceId: sinceId, maxId: maxId, direction: .downward)
    await datasource.insertGap(gap, at: index)
  }
}

// MARK: - Marker handling

extension TimelineViewModel {
  func fetchMarker() async -> Marker.Content? {
    guard let client else {
      return nil
    }
    do {
      let data: Marker = try await client.get(endpoint: Markers.markers)
      return data.home
    } catch {
      return nil
    }
  }

  func saveMarker() {
    guard timeline == .home, let client else { return }
    Task {
      guard let id = await cache.getLatestSeenStatus(for: client, filter: timeline.id)?.first else {
        return
      }
      do {
        let _: Marker = try await client.post(endpoint: Markers.markHome(lastReadId: id))
      } catch {}
    }
  }
}

// MARK: - Event handling

extension TimelineViewModel {
  func handleEvent(event: any StreamEvent) async {
    guard let client = client, canStreamEvents else { return }

    switch event {
    case let deleteEvent as StreamEventDelete:
      await handleDeleteEvent(deleteEvent)
    case let statusUpdateEvent as StreamEventStatusUpdate:
      await handleStatusUpdateEvent(statusUpdateEvent, client: client)
    default:
      break
    }
  }

  // Post streaming insertion is disabled for now.
  /*
  private func handleUpdateEvent(_ event: StreamEventUpdate, client: MastodonClient) async {
    guard timeline == .home,
      UserPreferences.shared.isPostsStreamingEnabled,
      await !datasource.contains(statusId: event.status.id),
      let topStatus = await datasource.get().first,
      topStatus.createdAt.asDate < event.status.createdAt.asDate
    else { return }
  
    pendingStatusesObserver.pendingStatuses.insert(event.status.id, at: 0)
    await datasource.insert(event.status, at: 0)
    await cache()
    StatusDataControllerProvider.shared.updateDataControllers(for: [event.status], client: client)
    await updateStatusesStateWithAnimation()
  }
   */

  private func handleDeleteEvent(_ event: StreamEventDelete) async {
    if await datasource.remove(event.status) != nil {
      await cache()
      await updateStatusesStateWithAnimation()
    }
  }

  private func handleStatusUpdateEvent(_ event: StreamEventStatusUpdate, client: MastodonClient) async {
    guard let originalIndex = await datasource.indexOf(statusId: event.status.id) else { return }

    StatusDataControllerProvider.shared.updateDataControllers(for: [event.status], client: client)
    await datasource.replace(event.status, at: originalIndex)
    await cache()
    await updateStatusesStateWithAnimation()
  }
}
