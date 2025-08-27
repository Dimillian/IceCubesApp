import Foundation
import Models

public enum NotificationsListState {
  public enum PagingState {
    case none, hasNextPage
  }
  
  case loading
  case display(notifications: [ConsolidatedNotification], nextPageState: PagingState)
  case error(error: Error)
}