import Foundation
import Models
import NetworkClient
import StatusKit
import Observation
import Env

@MainActor
@Observable
class AccountTabFetcher: StatusesFetcher {
  let accountId: String
  let client: MastodonClient
  let isCurrentUser: Bool
  
  var statusesState: StatusesState = .loading
  var statuses: [Status] = []
  
  init(accountId: String, client: MastodonClient, isCurrentUser: Bool) {
    self.accountId = accountId
    self.client = client
    self.isCurrentUser = isCurrentUser
  }
  
  func fetchNewestStatuses(pullToRefresh: Bool) async {
    fatalError("Subclasses must implement fetchNewestStatuses")
  }
  
  func fetchNextPage() async throws {
    fatalError("Subclasses must implement fetchNextPage")
  }
  
  func statusDidAppear(status: Status) {}
  
  func statusDidDisappear(status: Status) {}
  
  func updateStatusesState(with statuses: [Status], hasMore: Bool) {
    self.statuses = statuses
    statusesState = .display(
      statuses: statuses,
      nextPageState: hasMore ? .hasNextPage : .none
    )
  }
  
  func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    if let event = event as? StreamEventUpdate {
      if event.status.account.id == currentAccount.account?.id {
        statuses.insert(event.status, at: 0)
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    } else if let event = event as? StreamEventDelete {
      statuses.removeAll(where: { $0.id == event.status })
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } else if let event = event as? StreamEventStatusUpdate {
      if let originalIndex = statuses.firstIndex(where: { $0.id == event.status.id }) {
        StatusDataControllerProvider.shared.updateDataControllers(
          for: [event.status], client: client)
        statuses[originalIndex] = event.status
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    }
  }
}
