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
  
  var client: Client = .init(server: "")
  private var statuses: [Status] = []
  
  @Published var state: State = .loading
  
  var serverName: String {
    client.server
  }
    
  func refreshTimeline() async {
    do {
      statuses = try await client.fetch(endpoint: Timeline.pub(sinceId: nil))
      state = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      state = .error(error: error)
    }
  }
  
  func loadNextPage() async {
    do {
      guard let lastId = statuses.last?.id else { return }
      state = .display(statuses: statuses, nextPageState: .loadingNextPage)
      let newStatuses: [Status] = try await client.fetch(endpoint: Timeline.pub(sinceId: lastId))
      statuses.append(contentsOf: newStatuses)
      state = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      state = .error(error: error)
    }
  }
}
