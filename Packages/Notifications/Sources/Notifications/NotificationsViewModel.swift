import Env
import Foundation
import Models
import Network
import Observation
import SwiftUI

@MainActor
@Observable class NotificationsViewModel {
  public enum State {
    public enum PagingState {
      case none, hasNextPage
    }

    case loading
    case display(notifications: [ConsolidatedNotification], nextPageState: State.PagingState)
    case error(error: Error)
  }

  enum Constants {
    static let notificationLimit: Int = 30
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

  var currentAccount: CurrentAccount?

  private let filterKey = "notification-filter"
  var state: State = .loading
  var isLockedType: Bool = false
  var lockedAccountId: String?
  var policy: Models.NotificationsPolicy?
  var selectedType: Models.Notification.NotificationType? {
    didSet {
      guard oldValue != selectedType,
            client?.id != nil
      else { return }

      if !isLockedType {
        UserDefaults.standard.set(selectedType?.rawValue ?? "", forKey: filterKey)
      }

      consolidatedNotifications = []
    }
  }

  func loadSelectedType() {
    guard let value = UserDefaults.standard.string(forKey: filterKey)
    else {
      selectedType = nil
      return
    }

    selectedType = .init(rawValue: value)
  }

  var scrollToTopVisible: Bool = false

  private var queryTypes: [String]? {
    if let selectedType {
      var excludedTypes = Models.Notification.NotificationType.allCases
      excludedTypes.removeAll(where: { $0 == selectedType })
      return excludedTypes.map(\.rawValue)
    }
    return nil
  }

  private var consolidatedNotifications: [ConsolidatedNotification] = []

  func fetchNotifications() async {
    guard let client, let currentAccount else { return }
    do {
      var nextPageState: State.PagingState = .hasNextPage
      if consolidatedNotifications.isEmpty {
        state = .loading
        let notifications: [Models.Notification]
        if let lockedAccountId {
          notifications = try await client.get(endpoint: Notifications.notificationsForAccount(accountId: lockedAccountId,
                                                                                               maxId: nil))
        } else {
          notifications = try await client.get(endpoint: Notifications.notifications(minId: nil,
                                                                                     maxId: nil,
                                                                                     types: queryTypes,
                                                                                     limit: Constants.notificationLimit))
        }
        consolidatedNotifications = await notifications.consolidated(selectedType: selectedType)
        markAsRead()
        nextPageState = notifications.count < Constants.notificationLimit ? .none : .hasNextPage
      } else if let firstId = consolidatedNotifications.first?.id {
        var newNotifications: [Models.Notification] = await fetchNewPages(minId: firstId, maxPages: 10)
        nextPageState = consolidatedNotifications.notificationCount < Constants.notificationLimit ? .none : .hasNextPage
        newNotifications = newNotifications.filter { notification in
          !consolidatedNotifications.contains(where: { $0.id == notification.id })
        }

        await consolidatedNotifications.insert(
          contentsOf: newNotifications.consolidated(selectedType: selectedType),
          at: 0
        )
      }

      if consolidatedNotifications.contains(where: { $0.type == .follow_request }) {
        await currentAccount.fetchFollowerRequests()
      }

      markAsRead()

      withAnimation {
        state = .display(notifications: consolidatedNotifications,
                         nextPageState: consolidatedNotifications.isEmpty ? .none : nextPageState)
      }
    } catch {
      state = .error(error: error)
    }
  }

  private func fetchNewPages(minId: String, maxPages: Int) async -> [Models.Notification] {
    guard let client, lockedAccountId == nil else { return [] }
    var pagesLoaded = 0
    var allNotifications: [Models.Notification] = []
    var latestMinId = minId
    do {
      while let newNotifications: [Models.Notification] =
        try await client.get(endpoint: Notifications.notifications(minId: latestMinId,
                                                                   maxId: nil,
                                                                   types: queryTypes,
                                                                   limit: Constants.notificationLimit)),
        !newNotifications.isEmpty,
        pagesLoaded < maxPages
      {
        pagesLoaded += 1

        allNotifications.insert(contentsOf: newNotifications, at: 0)
        latestMinId = newNotifications.first?.id ?? ""
      }
    } catch {
      return allNotifications
    }
    return allNotifications
  }

  func fetchNextPage() async throws {
    guard let client else { return }
    guard let lastId = consolidatedNotifications.last?.notificationIds.last else { return }
    let newNotifications: [Models.Notification]
    if let lockedAccountId {
      newNotifications =
        try await client.get(endpoint: Notifications.notificationsForAccount(accountId: lockedAccountId, maxId: lastId))
    } else {
      newNotifications =
        try await client.get(endpoint: Notifications.notifications(minId: nil,
                                                                   maxId: lastId,
                                                                   types: queryTypes,
                                                                   limit: Constants.notificationLimit))
    }
    await consolidatedNotifications.append(contentsOf: newNotifications.consolidated(selectedType: selectedType))
    if consolidatedNotifications.contains(where: { $0.type == .follow_request }) {
      await currentAccount?.fetchFollowerRequests()
    }
    state = .display(notifications: consolidatedNotifications,
                     nextPageState: newNotifications.count < Constants.notificationLimit ? .none : .hasNextPage)
  }

  func markAsRead() {
    guard let client, let id = consolidatedNotifications.first?.notifications.first?.id else { return }
    Task {
      do {
        let _: Marker = try await client.post(endpoint: Markers.markNotifications(lastReadId: id))
      } catch {}
    }
  }

  func fetchPolicy() async {
    policy = try? await client?.get(endpoint: Notifications.policy)
  }

  func handleEvent(event: any StreamEvent) {
    Task {
      // Check if the event is a notification,
      // if it is not already in the list,
      // and if it can be shown (no selected type or the same as the received notification type)
      if lockedAccountId == nil,
         let event = event as? StreamEventNotification,
         !consolidatedNotifications.flatMap(\.notificationIds).contains(event.notification.id),
         selectedType == nil || selectedType?.rawValue == event.notification.type
      {
        if event.notification.isConsolidable(selectedType: selectedType),
           !consolidatedNotifications.isEmpty
        {
          // If the notification type can be consolidated, try to consolidate with the latest row
          let latestConsolidatedNotification = consolidatedNotifications.removeFirst()
          await consolidatedNotifications.insert(
            contentsOf: ([event.notification] + latestConsolidatedNotification.notifications)
              .consolidated(selectedType: selectedType),
            at: 0
          )
        } else {
          // Otherwise, just insert the new notification
          await consolidatedNotifications.insert(
            contentsOf: [event.notification].consolidated(selectedType: selectedType),
            at: 0
          )
        }

        if event.notification.supportedType == .follow_request, let currentAccount {
          await currentAccount.fetchFollowerRequests()
        }

        withAnimation {
          state = .display(notifications: consolidatedNotifications, nextPageState: .hasNextPage)
        }
      }
    }
  }
}
