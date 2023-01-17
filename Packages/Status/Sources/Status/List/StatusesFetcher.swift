import Models
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
public protocol StatusesFetcher: ObservableObject {
  var statusesState: StatusesState { get }
  func fetchStatuses() async
  func fetchNextPage() async
}
