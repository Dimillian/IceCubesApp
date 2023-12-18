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
      case none, hasNextPage, loadingNextPage
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
  var selectedType: Models.Notification.NotificationType? {
    didSet {
      guard oldValue != selectedType,
            let id = client?.id
      else { return }

      UserDefaults.standard.set(selectedType?.rawValue ?? "", forKey: filterKey)

      consolidatedNotifications = []
      Task {
        await fetchNotifications()
      }
    }
  }

  func loadSelectedType() {
    client = client

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
        let notifications: [Models.Notification] =
          try await client.get(endpoint: Notifications.notifications(minId: nil,
                                                                     maxId: nil,
                                                                     types: queryTypes,
                                                                     limit: Constants.notificationLimit))
        consolidatedNotifications = await notifications.consolidated(selectedType: selectedType)
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

      withAnimation {
        state = .display(notifications: consolidatedNotifications,
                         nextPageState: consolidatedNotifications.isEmpty ? .none : nextPageState)
      }
    } catch {
      state = .error(error: error)
    }
  }

  private func fetchNewPages(minId: String, maxPages: Int) async -> [Models.Notification] {
    guard let client else { return [] }
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

  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = consolidatedNotifications.last?.notificationIds.last else { return }
      state = .display(notifications: consolidatedNotifications, nextPageState: .loadingNextPage)
      let newNotifications: [Models.Notification] =
        try await client.get(endpoint: Notifications.notifications(minId: nil,
                                                                   maxId: lastId,
                                                                   types: queryTypes,
                                                                   limit: Constants.notificationLimit))
      await consolidatedNotifications.append(contentsOf: newNotifications.consolidated(selectedType: selectedType))
      if consolidatedNotifications.contains(where: { $0.type == .follow_request }) {
        await currentAccount?.fetchFollowerRequests()
      }
      state = .display(notifications: consolidatedNotifications,
                       nextPageState: newNotifications.count < Constants.notificationLimit ? .none : .hasNextPage)
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
