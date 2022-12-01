import SwiftUI
import Network
import Models

@MainActor
class TimelineViewModel: ObservableObject {
  enum State {
    enum PadingState {
      case hasNextPage, loadingNextPage
    }
    case loading
    case display(statuses: [Status], nextPageState: State.PadingState)
    case error(error: Error)
  }
  
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
  
  @Published var state: State = .loading
  @Published var timeline: TimelineFilter = .pub {
    didSet {
      if oldValue != timeline {
        Task {
          await refreshTimeline()
        }
      }
    }
  }
  
  var serverName: String {
    client.server
  }
    
  func refreshTimeline() async {
    do {
      state = .loading
      statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil))
      state = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      state = .error(error: error)
    }
  }
  
  func loadNextPage() async {
    do {
      guard let lastId = statuses.last?.id else { return }
      state = .display(statuses: statuses, nextPageState: .loadingNextPage)
      let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: lastId))
      statuses.append(contentsOf: newStatuses)
      state = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      state = .error(error: error)
    }
  }
}
