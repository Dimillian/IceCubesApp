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
    case display(notifications: [ConsolidatedNotification], nextPageState: State.PagingState)
    case error(error: Error)
  }

  public enum Tab: LocalizedStringKey, CaseIterable {
    case all = "notifications.tab.all"
    case mentions = "notifications.tab.mentions"
  }

  var client: Client? {
    didSet {
      if oldValue != client {
        consolidatedNotifications = []
      }
    }
  }

  @Published var state: State = .loading
  @Published var selectedType: Models.Notification.NotificationType? {
    didSet {
      if oldValue != selectedType {
        consolidatedNotifications = []
        Task {
          await fetchNotifications()
        }
      }
    }
  }

  private var queryTypes: [String]? {
    if let selectedType {
      var excludedTypes = Models.Notification.NotificationType.allCases
      excludedTypes.removeAll(where: { $0 == selectedType })
      return excludedTypes.map { $0.rawValue }
    }
    return nil
  }

  private var consolidatedNotifications: [ConsolidatedNotification] = []

  func fetchNotifications() async {
    guard let client else { return }
    do {
      var nextPageState: State.PagingState = .hasNextPage
      if consolidatedNotifications.isEmpty {
        state = .loading
        let notifications: [Models.Notification] =
          try await client.get(endpoint: Notifications.notifications(sinceId: nil,
                                                                     maxId: nil,
                                                                     types: queryTypes))
        consolidatedNotifications = notifications.consolidated(selectedType: selectedType)
        nextPageState = notifications.count < 15 ? .none : .hasNextPage
      } else if let first = consolidatedNotifications.first {
        var newNotifications: [Models.Notification] =
          try await client.get(endpoint: Notifications.notifications(sinceId: first.id,
                                                                     maxId: nil,
                                                                     types: queryTypes))
        nextPageState = consolidatedNotifications.notificationCount < 15 ? .none : .hasNextPage
        newNotifications = newNotifications.filter { notification in
          !consolidatedNotifications.contains(where: { $0.id == notification.id })
        }
        consolidatedNotifications.insert(
          contentsOf: newNotifications.consolidated(selectedType: selectedType),
          at: 0
        )
      }
      withAnimation {
        state = .display(notifications: consolidatedNotifications,
                         nextPageState: consolidatedNotifications.isEmpty ? .none : nextPageState)
      }
    } catch {
      state = .error(error: error)
    }
  }

  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = consolidatedNotifications.last?.notificationIds.last else { return }
      state = .display(notifications: consolidatedNotifications, nextPageState: .loadingNextPage)
      let newNotifications: [Models.Notification] =
        try await client.get(endpoint: Notifications.notifications(sinceId: nil,
                                                                   maxId: lastId,
                                                                   types: queryTypes))
      consolidatedNotifications.append(contentsOf: newNotifications.consolidated(selectedType: selectedType))
      state = .display(notifications: consolidatedNotifications, nextPageState: newNotifications.count < 15 ? .none : .hasNextPage)
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
    Task {
      // Check if the event is a notification,
      // if it is not already in the list,
      // and if it can be shown (no selected type or the same as the received notification type)
      if let event = event as? StreamEventNotification,
         !consolidatedNotifications.flatMap(\.notificationIds).contains(event.notification.id),
         selectedType == nil || selectedType?.rawValue == event.notification.type
      {
        if event.notification.isConsolidable(selectedType: selectedType),
           !consolidatedNotifications.isEmpty {
          // If the notification type can be consolidated, try to consolidate with the latest row
          let latestConsolidatedNotification = consolidatedNotifications.removeFirst()
          consolidatedNotifications.insert(
            contentsOf: ([event.notification] + latestConsolidatedNotification.notifications)
              .consolidated(selectedType: selectedType),
            at: 0
          )
        } else {
          // Otherwise, just insert the new notification
          consolidatedNotifications.insert(
            contentsOf: [event.notification].consolidated(selectedType: selectedType),
            at: 0
          )
        }

        withAnimation {
          state = .display(notifications: consolidatedNotifications, nextPageState: .hasNextPage)
        }
      }
    }
  }
}
