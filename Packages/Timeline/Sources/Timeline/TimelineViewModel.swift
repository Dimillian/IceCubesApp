import SwiftUI
import Network
import Models
import Status
import Env

@MainActor
class TimelineViewModel: ObservableObject, StatusesFetcher {
  var client: Client?
  
  private var statuses: [Status] = []
  
  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .pub {
    didSet {
      Task {
        if oldValue != timeline {
          statuses = []
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
  @Published var pendingStatuses: [Status] = []
  
  var serverName: String {
    client?.server ?? "Error"
  }
    
  func fetchStatuses() async {
    guard let client else { return }
    do {
      if statuses.isEmpty {
        pendingStatuses = []
        statusesState = .loading
        statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil, maxId: nil))
      } else if let first = statuses.first {
        let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: first.id, maxId: nil))
        statuses.insert(contentsOf: newStatuses, at: 0)
      }
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
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
    guard timeline == .home else { return }
    if let event = event as? StreamEventUpdate {
      if event.status.account.id == currentAccount.account?.id {
        statuses.insert(event.status, at: 0)
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      } else {
        pendingStatuses.insert(event.status, at: 0)
      }
    } else if let event = event as? StreamEventDelete {
      statuses.removeAll(where: { $0.id == event.status })
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    }
  }
  
  func displayPendingStatuses() {
    guard timeline == .home else { return }
    statuses.insert(contentsOf: pendingStatuses, at: 0)
    pendingStatuses = []
    statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
  }
}
