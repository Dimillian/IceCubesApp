import Foundation
import SwiftUI
import Network
import Models

@MainActor
class NotificationsViewModel: ObservableObject {
  public enum State {
    public enum PagingState {
      case hasNextPage, loadingNextPage
    }
    case loading
    case display(notifications: [Models.Notification], nextPageState: State.PagingState)
    case error(error: Error)
  }
  
  var client: Client?
  @Published var state: State = .loading
  
  private var notifications: [Models.Notification] = []
  
  func fetchNotifications() async {
    guard let client else { return }
    do {
      if notifications.isEmpty {
        state = .loading
      }
      notifications = try await client.get(endpoint: Notifications.notifications(maxId: nil))
      state = .display(notifications: notifications, nextPageState: .hasNextPage)
    } catch {
      state = .error(error: error)
    }
  }
  
  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = notifications.last?.id else { return }
      state = .display(notifications: notifications, nextPageState: .loadingNextPage)
      let newNotifications: [Models.Notification] = try await client.get(endpoint: Notifications.notifications(maxId: lastId))
      notifications.append(contentsOf: newNotifications)
      state = .display(notifications: notifications, nextPageState: .hasNextPage)
    } catch {
      state = .error(error: error)
    }
  }
}
