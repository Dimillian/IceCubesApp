import Env
import Models
import Network
import Status
import SwiftUI

@MainActor
class TimelineViewModel: ObservableObject, StatusesFetcher {
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
  
  private var canStreamEvents: Bool = true
  
  var scrollProxy: ScrollViewProxy?
  
  var pendingStatusesObserver: PendingStatusesObserver = .init()

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
  @Published var pendingStatusesCount: Int = 0

  var pendingStatusesEnabled: Bool {
    timeline == .home
  }

  var serverName: String {
    client?.server ?? "Error"
  }

  func fetchStatuses() async {
    guard let client else { return }
    do {
      if statuses.isEmpty {
        pendingStatusesObserver.pendingStatuses = []
        statusesState = .loading
        statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                    maxId: nil,
                                                                    minId: nil,
                                                                    offset: statuses.count))
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
        }
      } else if let first = statuses.first {
        canStreamEvents = false
        var newStatuses: [Status] = await fetchNewPages(minId: first.id, maxPages: 10)
        if !pendingStatusesEnabled {
          statuses.insert(contentsOf: newStatuses, at: 0)
          pendingStatusesObserver.pendingStatuses = []
          withAnimation {
            statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
            canStreamEvents = true
          }
        } else {
          newStatuses = newStatuses.filter { status in
            !statuses.contains(where: { $0.id == status.id })
          }
          
          guard !newStatuses.isEmpty else {
            canStreamEvents = true
            return
          }
          
          pendingStatusesObserver.pendingStatuses.insert(contentsOf: newStatuses.map{ $0.id }, at: 0)
          pendingStatusesObserver.feedbackGenerator.impactOccurred()
          
          // High chance the user is scrolled to the top, this is a workaround to keep scroll position when prepending statuses.
          if let firstStatusId = statuses.first?.id, visibileStatusesIds.contains(firstStatusId) {
            statuses.insert(contentsOf: newStatuses, at: 0)
            pendingStatusesObserver.disableUpdate = true
            withAnimation {
              statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.scrollProxy?.scrollTo(firstStatusId, anchor: .top)
                self.pendingStatusesObserver.disableUpdate = false
                self.canStreamEvents = true
              }
            }
          } else {
            statuses.insert(contentsOf: newStatuses, at: 0)
            withAnimation {
              statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
              canStreamEvents = true
            }
          }
        }
      }
    } catch {
      statusesState = .error(error: error)
      canStreamEvents = true
      print("timeline parse error: \(error)")
    }
  }

  func fetchNewPages(minId: String, maxPages: Int) async -> [Status] {
    guard let client else { return [] }
    var pagesLoaded = 0
    var allStatuses: [Status] = []
    var latestMinId = minId
    do {
      while let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                         maxId: nil,
                                                                                         minId: latestMinId,
                                                                                         offset: statuses.count)),
        !newStatuses.isEmpty,
        pagesLoaded < maxPages
      {
        pagesLoaded += 1
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
      let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                   maxId: lastId,
                                                                                   minId: nil,
                                                                                   offset: statuses.count))
      statuses.append(contentsOf: newStatuses)
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }

  func fetchTag(id: String) async {
    guard let client else { return }
    do {
      tag = try await client.get(endpoint: Tags.tag(id: id))
    } catch {}
  }

  func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    if let event = event as? StreamEventUpdate,
       canStreamEvents,
       pendingStatusesEnabled,
       !statuses.contains(where: { $0.id == event.status.id })
    {
      pendingStatusesObserver.pendingStatuses.insert(event.status.id, at: 0)
      statuses.insert(event.status, at: 0)
      withAnimation {
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    } else if let event = event as? StreamEventDelete {
      withAnimation {
        statuses.removeAll(where: { $0.id == event.status })
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    } else if let event = event as? StreamEventStatusUpdate {
      if let originalIndex = statuses.firstIndex(where: { $0.id == event.status.id }) {
        statuses[originalIndex] = event.status
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
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
