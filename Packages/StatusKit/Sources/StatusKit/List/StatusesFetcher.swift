import Combine
import Models
import Observation
import SwiftUI

public enum StatusesState: Equatable, Sendable {
  public enum PagingState: Equatable, Sendable {
    case hasNextPage, none
  }

  public enum ErrorState: Equatable, Sendable {
    case noData
  }

  case loading
  case display(statuses: [Status], nextPageState: StatusesState.PagingState)
  case displayWithGaps(items: [TimelineItem], nextPageState: StatusesState.PagingState)
  case error(error: ErrorState)
}

@MainActor
public protocol StatusesFetcher: Sendable {
  var statusesState: StatusesState { get }
  func fetchNewestStatuses(pullToRefresh: Bool) async
  func fetchNextPage() async throws
  func statusDidAppear(status: Status)
  func statusDidDisappear(status: Status)
}

@MainActor
public protocol GapLoadingFetcher: StatusesFetcher {
  func loadGap(gap: TimelineGap) async
}
