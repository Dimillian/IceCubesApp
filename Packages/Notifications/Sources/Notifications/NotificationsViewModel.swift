import Foundation
import Models
import Network
import SwiftUI

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

  var client: Client? {
    didSet {
      if oldValue != client {
        notifications = []
      }
    }
  }

  @Published var state: State = .loading
  @Published var selectedType: Models.Notification.NotificationType? {
    didSet {
      if oldValue != selectedType {
        notifications = []
        Task {
          await fetchNotifications()
        }
      }
    }
  }

  private var queryTypes: [String]? {
    if let selectedType {
      var excludedTypes = Models.Notification.NotificationType.allCases
      excludedTypes.removeAll(where: { $0 == selectedType})
      return excludedTypes.map{ $0.rawValue }
    }
    return nil
  }

  private var notifications: [Models.Notification] = []

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
        var newNotifications: [Models.Notification] =
          try await client.get(endpoint: Notifications.notifications(sinceId: first.id,
                                                                     maxId: nil,
                                                                     types: queryTypes))
        nextPageState = notifications.count < 15 ? .none : .hasNextPage
        newNotifications = newNotifications.filter { notification in
          !notifications.contains(where: { $0.id == notification.id })
        }
        notifications.insert(contentsOf: newNotifications, at: 0)
      }
      withAnimation {
        state = .display(notifications: notifications,
                         nextPageState: notifications.isEmpty ? .none : nextPageState)
      }
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
    } catch {}
  }

  func handleEvent(event: any StreamEvent) {
    if  let event = event as? StreamEventNotification,
       !notifications.contains(where: { $0.id == event.notification.id })
    {
      if let selectedType, event.notification.type == selectedType.rawValue {
        notifications.insert(event.notification, at: 0)
      } else {
        notifications.insert(event.notification, at: 0)
      }
      state = .display(notifications: notifications, nextPageState: .hasNextPage)
    }
  }
}
