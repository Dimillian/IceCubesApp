import Env
import Models
import Network
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
  private(set) var datasource = TimelineDatasource()
  private let statusFetcher: TimelineStatusFetching
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

  var client: Client? {
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

  var isTimelineVisible: Bool = false
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

extension TimelineViewModel: StatusesFetcher {
  func pullToRefresh() async {
    timelineTask?.cancel()

    if !timeline.supportNewestPagination || UserPreferences.shared.fastRefreshEnabled {
      await reset()
    }
    await fetchNewestStatuses(pullToRefresh: true)
  }

  func refreshTimeline() {
    timelineTask?.cancel()
    timelineTask = Task {
      if UserPreferences.shared.fastRefreshEnabled {
        await reset()
      }
      await fetchNewestStatuses(pullToRefresh: false)
    }
  }

  func refreshTimelineContentFilter() async {
    timelineTask?.cancel()
    let statuses = await datasource.getFiltered()
    withAnimation {
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    }
  }

  func fetchStatuses(from: Marker.Content) async throws {
    guard let client else { return }
    statusesState = .loading
    var statuses: [Status] = try await client.get(
      endpoint: timeline.endpoint(
        sinceId: nil,
        maxId: from.lastReadId,
        minId: nil,
        offset: 0,
        limit: 40))

    StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)

    await datasource.set(statuses)
    await cache()
    statuses = await datasource.getFiltered()
    marker = nil

    withAnimation {
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    }

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
        statusesState = .error(error: error)
      }
      canStreamEvents = true
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
    if timeline.supportNewestPagination,
      let cachedStatuses = await getCachedStatuses(),
      !cachedStatuses.isEmpty,
      !UserPreferences.shared.fastRefreshEnabled
    {
      await datasource.set(cachedStatuses)
      let statuses = await datasource.getFiltered()
      if let latestSeenId = await cache.getLatestSeenStatus(for: client, filter: timeline.id)?.first
      {
        // Restore cache and scroll to latest seen status.
        scrollToId = latestSeenId
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      } else {
        // Restore cache and scroll to top.
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        }
      }
      // And then we fetch statuses again toget newest statuses from there.
      await fetchNewestStatuses(pullToRefresh: false)
    } else {
      var statuses: [Status] = try await statusFetcher.fetchFirstPage(
        client: client,
        timeline: timeline)

      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)

      await datasource.set(statuses)
      await cache()
      statuses = await datasource.getFiltered()

      withAnimation {
        statusesState = .display(
          statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
      }
    }
  }

  // Fetch pages from the top most status of the timeline.
  private func fetchNewPagesFrom(latestStatus: String, client: Client) async throws {
    canStreamEvents = false
    let initialTimeline = timeline

    let newStatuses = try await fetchAndDedupNewStatuses(
      latestStatus: latestStatus,
      client: client)

    guard !newStatuses.isEmpty,
      isTimelineVisible,
      !Task.isCancelled,
      initialTimeline == timeline
    else {
      canStreamEvents = true
      return
    }

    await updateTimelineWithNewStatuses(newStatuses)

    if !Task.isCancelled, let latest = await datasource.get().first {
      pendingStatusesObserver.isLoadingNewStatuses = true
      try await fetchNewPagesFrom(latestStatus: latest.id, client: client)
    }
  }

  private func fetchAndDedupNewStatuses(latestStatus: String, client: Client) async throws
    -> [Status]
  {
    var newStatuses = try await statusFetcher.fetchNewPages(
      client: client,
      timeline: timeline,
      minId: latestStatus,
      maxPages: 5)
    let ids = await datasource.get().map(\.id)
    newStatuses = newStatuses.filter { status in
      !ids.contains(where: { $0 == status.id })
    }
    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)
    return newStatuses
  }

  private func updateTimelineWithNewStatuses(_ newStatuses: [Status]) async {
    defer {
      canStreamEvents = true
    }
    let topStatus = await datasource.getFiltered().first
    await datasource.insert(contentOf: newStatuses, at: 0)
    if let lastVisible = visibleStatuses.last {
      await datasource.remove(after: lastVisible, safeOffset: 15)
    }
    await cache()
    pendingStatusesObserver.pendingStatuses.insert(contentsOf: newStatuses.map(\.id), at: 0)

    let statuses = await datasource.getFiltered()

    if let topStatus = topStatus,
      visibleStatuses.contains(where: { $0.id == topStatus.id }),
      scrollToTopVisible
    {
      scrollToId = topStatus.id
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } else {
      withAnimation {
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
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

    statusesState = await .display(
      statuses: datasource.getFiltered(),
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
    guard let client = client, canStreamEvents, isTimelineVisible else { return }

    switch event {
    case let updateEvent as StreamEventUpdate:
      await handleUpdateEvent(updateEvent, client: client)
    case let deleteEvent as StreamEventDelete:
      await handleDeleteEvent(deleteEvent)
    case let statusUpdateEvent as StreamEventStatusUpdate:
      await handleStatusUpdateEvent(statusUpdateEvent, client: client)
    default:
      break
    }
  }

  private func handleUpdateEvent(_ event: StreamEventUpdate, client: Client) async {
    guard timeline == .home,
      UserPreferences.shared.isPostsStreamingEnabled,
      await !datasource.contains(statusId: event.status.id)
    else { return }

    pendingStatusesObserver.pendingStatuses.insert(event.status.id, at: 0)
    await datasource.insert(event.status, at: 0)
    await cache()
    StatusDataControllerProvider.shared.updateDataControllers(for: [event.status], client: client)
    await updateStatusesState()
  }

  private func handleDeleteEvent(_ event: StreamEventDelete) async {
    if await datasource.remove(event.status) != nil {
      await cache()
      await updateStatusesState()
    }
  }

  private func handleStatusUpdateEvent(_ event: StreamEventStatusUpdate, client: Client) async {
    guard let originalIndex = await datasource.indexOf(statusId: event.status.id) else { return }

    StatusDataControllerProvider.shared.updateDataControllers(for: [event.status], client: client)
    await datasource.replace(event.status, at: originalIndex)
    await cache()
    await updateStatusesState()
  }

  private func updateStatusesState() async {
    let statuses = await datasource.getFiltered()
    withAnimation {
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    }
  }
}
