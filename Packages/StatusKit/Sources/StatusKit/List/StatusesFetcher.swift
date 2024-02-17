import Combine
import Models
import Observation
import SwiftUI

public enum StatusesState {
  public enum PagingState {
    case hasNextPage, none
  }

  case loading
  case display(statuses: [Status], nextPageState: StatusesState.PagingState)
  case error(error: Error)
}

@MainActor
public protocol StatusesFetcher {
  var statusesState: StatusesState { get }
  func fetchNewestStatuses(pullToRefresh: Bool) async
  func fetchNextPage() async throws
  func statusDidAppear(status: Status)
  func statusDidDisappear(status: Status)
}
