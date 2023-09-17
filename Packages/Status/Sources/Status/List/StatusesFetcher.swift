import Combine
import Models
import Observation
import SwiftUI

public enum StatusesState {
  public enum PagingState {
    case hasNextPage, loadingNextPage, none
  }

  case loading
  case display(statuses: [Status], nextPageState: StatusesState.PagingState)
  case error(error: Error)
}

@MainActor
public protocol StatusesFetcher {
  var statusesState: StatusesState { get }
  func fetchNewestStatuses() async
  func fetchNextPage() async
  func statusDidAppear(status: Status)
  func statusDidDisappear(status: Status)
}
