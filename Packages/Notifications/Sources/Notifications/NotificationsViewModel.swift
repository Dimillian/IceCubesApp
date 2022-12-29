import Foundation
import SwiftUI
import Network
import Models

@MainActor
class NotificationsViewModel: ObservableObject {
  public enum State {
    public enum PagingState {
      case none, hasNextPage, loadingNextPage
    }
    case loading
    case display(notifications: [Models.Notification], nextPageState: State.PagingState)
    case error(error: Error)
  }
  
  public enum Tab: String, CaseIterable {
    case all = "All"
    case mentions = "Mentions"
  }
  
  var client: Client?
  @Published var state: State = .loading
  @Published var tab: Tab = .all {
    didSet {
      notifications = []
      Task {
        await fetchNotifications()
      }
    }
  }
  
  private var notifications: [Models.Notification] = []
  private var queryTypes: [String]? {
    tab == .mentions ? ["mention"] : nil
  }
  
  func fetchNotifications() async {
    guard let client else { return }
    do {
      var nextPageState: State.PagingState = .hasNextPage
      if notifications.isEmpty {
        state = .loading
        notifications = try await client.get(endpoint: Notifications.notifications(sinceId: nil,
                                                                                   maxId: nil,
                                                                                   types: queryTypes))
        nextPageState = notifications.count < 15 ? .none : .hasNextPage
      } else if let first = notifications.first {
        let newNotifications: [Models.Notification] =
        try await client.get(endpoint: Notifications.notifications(sinceId: first.id,
                                                                   maxId: nil,
                                                                   types: queryTypes))
        nextPageState = notifications.count < 15 ? .none : .hasNextPage
        notifications.insert(contentsOf: newNotifications, at: 0)
      }
      state = .display(notifications: notifications,
                       nextPageState: notifications.isEmpty ? .none : nextPageState)
    } catch {
      state = .error(error: error)
    }
  }
  
  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = notifications.last?.id else { return }
      state = .display(notifications: notifications, nextPageState: .loadingNextPage)
      let newNotifications: [Models.Notification] =
      try await client.get(endpoint: Notifications.notifications(sinceId: nil,
                                                                 maxId: lastId,
                                                                 types: queryTypes))
      notifications.append(contentsOf: newNotifications)
      state = .display(notifications: notifications, nextPageState: newNotifications.count < 15 ? .none : .hasNextPage)
    } catch {
      state = .error(error: error)
    }
  }
  
  func clear() async {
    guard let client else { return }
    do {
      let _: ServerError = try await client.post(endpoint: Notifications.clear)
    } catch { }
  }
  
  func handleEvent(event: any StreamEvent) {
    if let event = event as? StreamEventNotification {
      notifications.insert(event.notification, at: 0)
      state = .display(notifications: notifications, nextPageState: .hasNextPage)
    }
  }
}
