import SwiftUI
import Network
import Models
import Status

@MainActor
class TimelineViewModel: ObservableObject, StatusesFetcher {
  enum TimelineFilter: String, CaseIterable {
    case pub = "Public"
    case home = "Home"
    
    func endpoint(sinceId: String?) -> Timelines {
      switch self {
        case .pub: return .pub(sinceId: sinceId)
        case .home: return .home(sinceId: sinceId)
      }
    }
  }
  
  var client: Client = .init(server: "") {
    didSet {
      timeline = client.isAuth ? .home : .pub
    }
  }
  
  private var statuses: [Status] = []
  
  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .pub {
    didSet {
      if oldValue != timeline {
        Task {
          await fetchStatuses()
        }
      }
    }
  }
  
  var serverName: String {
    client.server
  }
    
  func fetchStatuses() async {
    do {
      statusesState = .loading
      statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil))
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }
  
  func fetchNextPage() async {
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
