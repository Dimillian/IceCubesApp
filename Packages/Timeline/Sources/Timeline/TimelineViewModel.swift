import SwiftUI
import Network
import Models
import Status

@MainActor
class TimelineViewModel: ObservableObject, StatusesFetcher {
  var client: Client?
  
  private var statuses: [Status] = []
  
  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .pub {
    didSet {
      if oldValue != timeline || statuses.isEmpty {
        Task {
          await fetchStatuses()
        }
      }
    }
  }
  
  var serverName: String {
    client?.server ?? "Error"
  }
    
  func fetchStatuses() async {
    guard let client else { return }
    do {
      statusesState = .loading
      statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil))
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }
  
  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = statuses.last?.id else { return }
      statusesState = .display(statuses: statuses, nextPageState: .loadingNextPage)
      let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: lastId))
      statuses.append(contentsOf: newStatuses)
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }
}
