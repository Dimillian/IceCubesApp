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

  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .federated {
    didSet {
      Task {
        if oldValue != timeline {
          statuses = []
          pendingStatuses = []
          tag = nil
        }
        await fetchStatuses(userIntent: false)
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
  @Published var pendingStatuses: [Status] = []

  var pendingStatusesButtonTitle: LocalizedStringKey {
    "\(pendingStatuses.count)"
  }

  var pendingStatusesEnabled: Bool {
    timeline == .home
  }

  var serverName: String {
    client?.server ?? "Error"
  }

  func fetchStatuses() async {
    await fetchStatuses(userIntent: false)
  }

  func fetchStatuses(userIntent: Bool) async {
    guard let client else { return }
    do {
      if statuses.isEmpty {
        pendingStatuses = []
        statusesState = .loading
        statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                    maxId: nil,
                                                                    minId: nil,
                                                                    offset: statuses.count))


        ReblogCache.shared.removeDuplicateReblogs(&statuses)

        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
        }
      } else if let first = pendingStatuses.first ?? statuses.first {
        var newStatuses: [Status] = await fetchNewPages(minId: first.id, maxPages: 20)
        
        
        ReblogCache.shared.removeDuplicateReblogs(&newStatuses)

        
        if userIntent || !pendingStatusesEnabled {
          statuses.insert(contentsOf: pendingStatuses, at: 0)
          pendingStatuses = []
          withAnimation {
            statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
          }
        } else {
          newStatuses = newStatuses.filter { status in
            !statuses.contains(where: { $0.id == status.id })
          }
          pendingStatuses.insert(contentsOf: newStatuses, at: 0)
          statuses.insert(contentsOf: newStatuses, at: 0)
          withAnimation {
            statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
          }
        }
      }
    } catch {
      statusesState = .error(error: error)
      print("timeline parse error: \(error)")
    }
  }

  func fetchNewPages(minId: String, maxPages: Int) async -> [Status] {
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

      ReblogCache.shared.removeDuplicateReblogs(&newStatuses)


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
       pendingStatusesEnabled,
       !statuses.contains(where: { $0.id == event.status.id })
    {
      pendingStatuses.insert(event.status, at: 0)
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

  func statusDidAppear(status: Status) async {
    if let index = pendingStatuses.firstIndex(of: status) {
      pendingStatuses.remove(at: index)
    }
  }
}
