import SwiftUI
import Network
import Models
import Status
import Env

@MainActor
class TimelineViewModel: ObservableObject, StatusesFetcher {
  var client: Client?
  
  // Internal source of truth for a timeline.
  private var statuses: [Status] = []
  
  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .pub {
    didSet {
      Task {
        if oldValue != timeline {
          statuses = []
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
  
  enum PendingStatusesState {
    case refresh, stream
  }
  
  @Published var pendingStatuses: [Status] = []
  @Published var pendingStatusesState: PendingStatusesState = .stream
  
  var pendingStatusesButtonTitle: String {
    switch pendingStatusesState {
    case .stream:
      return "\(pendingStatuses.count) new posts"
    case .refresh:
      return "See new posts"
    }
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
      pendingStatuses = []
      if statuses.isEmpty {
        statusesState = .loading
        statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil, maxId: nil))
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      } else if let first = statuses.first {
        let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: first.id, maxId: nil))
        if userIntent || !pendingStatusesEnabled {
          statuses.insert(contentsOf: newStatuses, at: 0)
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        } else {
          pendingStatuses = newStatuses
          pendingStatusesState = .refresh
        }
      }
    } catch {
      statusesState = .error(error: error)
      print("timeline parse error: \(error)")
    }
  }
  
  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = statuses.last?.id else { return }
      statusesState = .display(statuses: statuses, nextPageState: .loadingNextPage)
      let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil, maxId: lastId))
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
  
  func followTag(id: String) async {
    guard let client else { return }
    do {
      tag = try await client.post(endpoint: Tags.follow(id: id))
    } catch {}
  }
  
  func unfollowTag(id: String) async {
    guard let client else { return }
    do {
      tag = try await client.post(endpoint: Tags.unfollow(id: id))
    } catch {}
  }
  
  func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    if let event = event as? StreamEventUpdate {
      if event.status.account.id == currentAccount.account?.id,
         timeline == .home {
        statuses.insert(event.status, at: 0)
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      } else if pendingStatusesEnabled,
                !statuses.contains(where: { $0.id == event.status.id }) {
        pendingStatuses.insert(event.status, at: 0)
        pendingStatusesState = .stream
      }
    } else if let event = event as? StreamEventDelete {
      statuses.removeAll(where: { $0.id == event.status })
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } else if let event = event as? StreamEventStatusUpdate {
      if let originalIndex = statuses.firstIndex(where: { $0.id == event.status.id }) {
        statuses[originalIndex] = event.status
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    }
  }
  
  func displayPendingStatuses() {
    guard timeline == .home else { return }
    pendingStatuses = pendingStatuses.filter { status in
      !statuses.contains(where: { $0.id == status.id })
    }
    statuses.insert(contentsOf: pendingStatuses, at: 0)
    pendingStatuses = []
    statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
  }
}
