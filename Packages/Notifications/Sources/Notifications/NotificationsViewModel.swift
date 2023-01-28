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
        notifications = []
        consolidatedNotifications = []
      }
    }
  }

  @Published var state: State = .loading
  @Published var selectedType: Models.Notification.NotificationType? {
    didSet {
      if oldValue != selectedType {
        notifications = []
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

  private var notifications: [Models.Notification] = []
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
        self.notifications = notifications
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
        notifications.append(contentsOf: newNotifications)
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
      notifications.append(contentsOf: newNotifications)
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
    if let event = event as? StreamEventNotification,
       !consolidatedNotifications.contains(where: { $0.id == event.notification.id })
    {
      if let selectedType, event.notification.type == selectedType.rawValue {
        notifications.insert(event.notification, at: 0)
        consolidatedNotifications = notifications.consolidated(selectedType: selectedType)
      } else if selectedType == nil {
        notifications.insert(event.notification, at: 0)
        consolidatedNotifications = notifications.consolidated(selectedType: selectedType)
      }
      state = .display(notifications: consolidatedNotifications, nextPageState: .hasNextPage)
    }
  }
}

struct ConsolidatedNotification: Identifiable {
  let notificationIds: [String]
  let type: Models.Notification.NotificationType
  let createdAt: ServerDate
  let accounts: [Account]
  let status: Status?

  var id: String? { notificationIds.first }

  static func placeholder() -> ConsolidatedNotification {
    .init(notificationIds: [UUID().uuidString],
          type: .favourite,
          createdAt: "2022-12-16T10:20:54.000Z",
          accounts: [.placeholder()],
          status: .placeholder())
  }

  static func placeholders() -> [ConsolidatedNotification] {
    [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
  }
}

extension Array where Element == Models.Notification {
  func consolidated(selectedType: Models.Notification.NotificationType?) -> [ConsolidatedNotification] {
    Dictionary(grouping: self) { notification -> String? in
      guard let supportedType = notification.supportedType else { return nil }

      switch supportedType {
      case .follow where selectedType != .follow:
        // Always group followers
        return supportedType.rawValue
      case .reblog, .favourite:
        // Group boosts and favourites by status
        return "\(supportedType.rawValue)-\(notification.status?.id ?? "")"
      default:
        // Never group remaining ones
        return notification.id
      }
    }
    .values
    .compactMap { notifications in
      guard let notification = notifications.first,
            let supportedType = notification.supportedType
      else { return nil }

      return ConsolidatedNotification(notificationIds: notifications.map(\.id),
                                      type: supportedType,
                                      createdAt: notification.createdAt,
                                      accounts: notifications.map(\.account),
                                      status: notification.status)
    }
    .sorted {
      $0.createdAt > $1.createdAt
    }
  }
}

extension Array where Element == ConsolidatedNotification {
  var notificationCount: Int {
    reduce(0) { $0 + ($1.accounts.isEmpty ? 1 : $1.accounts.count) }
  }
}
