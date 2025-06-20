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
  private var lastNotificationGroup: Models.NotificationGroup?

  func fetchNotifications(_ selectedType: Models.Notification.NotificationType?) async {
    guard let client, let currentAccount else { return }
    do {
      let useV2API =
        CurrentInstance.shared.isGroupedNotificationsSupported && lockedAccountId == nil

      if consolidatedNotifications.isEmpty {
        // Initial load
        state = .loading
        if useV2API {
          try await fetchNotificationsV2(client: client, selectedType: selectedType)
        } else {
          try await fetchNotificationsV1(client: client, selectedType: selectedType)
        }
      } else {
        // Pull to refresh
        if useV2API {
          try await refreshNotificationsV2(client: client, selectedType: selectedType)
        } else {
          try await refreshNotificationsV1(client: client, selectedType: selectedType)
        }
      }

      if consolidatedNotifications.contains(where: { $0.type == .follow_request }) {
        await currentAccount.fetchFollowerRequests()
      }

      markAsRead()

      withAnimation {
        state = .display(
          notifications: consolidatedNotifications,
          nextPageState: consolidatedNotifications.isEmpty
            ? .none
            : (lastNotificationGroup != nil
              || consolidatedNotifications.count >= Constants.notificationLimit
              ? .hasNextPage : .none))
      }
    } catch {
      state = .error(error: error)
    }
  }

  // MARK: - V1 API Methods

  private func fetchNotificationsV1(
    client: Client, selectedType: Models.Notification.NotificationType?
  ) async throws {
    let notifications: [Models.Notification]
    if let lockedAccountId {
      notifications = try await client.get(
        endpoint: Notifications.notificationsForAccount(
          accountId: lockedAccountId,
          maxId: nil))
    } else {
      notifications = try await client.get(
        endpoint: Notifications.notifications(
          minId: nil,
          maxId: nil,
          types: queryTypes,
          limit: Constants.notificationLimit))
    }
    consolidatedNotifications = await notifications.consolidated(selectedType: selectedType)
  }

  private func refreshNotificationsV1(
    client: Client, selectedType: Models.Notification.NotificationType?
  ) async throws {
    guard let firstId = consolidatedNotifications.first?.id else { return }

    var newNotifications: [Models.Notification] = await fetchNewPages(
      minId: firstId, maxPages: 10)
    newNotifications = newNotifications.filter { notification in
      !consolidatedNotifications.contains(where: { $0.id == notification.id })
    }

    consolidatedNotifications.insert(
      contentsOf: await newNotifications.consolidated(selectedType: selectedType),
      at: 0
    )
  }

  // MARK: - V2 API Methods

  private func fetchNotificationsV2(
    client: Client, selectedType: Models.Notification.NotificationType?
  ) async throws {
    let results = try await fetchGroupedNotifications(
      client: client,
      sinceId: nil,
      maxId: nil,
      selectedType: selectedType
    )
    consolidatedNotifications = results.consolidated
    lastNotificationGroup = results.lastGroup
  }

  private func refreshNotificationsV2(
    client: Client, selectedType: Models.Notification.NotificationType?
  ) async throws {
    // For V2 API pull-to-refresh: fetch new notifications since the first one
    guard let firstGroup = consolidatedNotifications.first else { return }

    // Use the most recent notification ID from the first group as sinceId
    let sinceId = firstGroup.notifications.first?.id ?? firstGroup.groupKey

    let results = try await fetchGroupedNotifications(
      client: client,
      sinceId: sinceId,
      maxId: nil,
      selectedType: selectedType
    )

    // Merge new notifications at the top, similar to streaming logic
    for newGroup in results.consolidated.reversed() {
      if let groupKey = newGroup.groupKey {
        // Check if we already have this group
        if let existingIndex = consolidatedNotifications.firstIndex(where: {
          $0.groupKey == groupKey
        }) {
          // Merge into existing group - add new accounts if not present
          let existingGroup = consolidatedNotifications[existingIndex]
          var updatedAccounts = existingGroup.accounts

          for newAccount in newGroup.accounts {
            if !updatedAccounts.contains(where: { $0.id == newAccount.id }) {
              updatedAccounts.insert(newAccount, at: 0)
            }
          }

          // Create updated consolidated notification
          let updatedGroup = ConsolidatedNotification(
            notifications: existingGroup.notifications,
            type: existingGroup.type,
            createdAt: newGroup.createdAt,  // Use the newer date
            accounts: updatedAccounts,
            status: existingGroup.status,
            groupKey: groupKey
          )

          // Remove old and insert updated at the top
          consolidatedNotifications.remove(at: existingIndex)
          consolidatedNotifications.insert(updatedGroup, at: 0)
        } else {
          // New group, insert at the top
          consolidatedNotifications.insert(newGroup, at: 0)
        }
      } else {
        // No group key, just insert at the top
        consolidatedNotifications.insert(newGroup, at: 0)
      }
    }
  }

  // MARK: - V1 API Helpers

  private func fetchNewPages(minId: String, maxPages: Int) async -> [Models.Notification] {
    guard let client, lockedAccountId == nil else { return [] }
    var pagesLoaded = 0
    var allNotifications: [Models.Notification] = []
    var latestMinId = minId
    do {
      while let newNotifications: [Models.Notification] =
        try await client.get(
          endpoint: Notifications.notifications(
            minId: latestMinId,
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

  func fetchNextPage(_ selectedType: Models.Notification.NotificationType?) async throws {
    guard let client else { return }

    let useV2API = CurrentInstance.shared.isGroupedNotificationsSupported && lockedAccountId == nil

    if useV2API {
      try await fetchNextPageV2(client: client, selectedType: selectedType)
    } else {
      try await fetchNextPageV1(client: client, selectedType: selectedType)
    }

    if consolidatedNotifications.contains(where: { $0.type == .follow_request }) {
      await currentAccount?.fetchFollowerRequests()
    }
  }

  // MARK: - V1 Pagination

  private func fetchNextPageV1(client: Client, selectedType: Models.Notification.NotificationType?)
    async throws
  {
    guard let lastId = consolidatedNotifications.last?.notificationIds.last else { return }

    let newNotifications: [Models.Notification]
    if let lockedAccountId {
      newNotifications = try await client.get(
        endpoint: Notifications.notificationsForAccount(accountId: lockedAccountId, maxId: lastId)
      )
    } else {
      newNotifications = try await client.get(
        endpoint: Notifications.notifications(
          minId: nil,
          maxId: lastId,
          types: queryTypes,
          limit: Constants.notificationLimit))
    }

    consolidatedNotifications.append(
      contentsOf: await newNotifications.consolidated(selectedType: selectedType))

    state = .display(
      notifications: consolidatedNotifications,
      nextPageState: newNotifications.count < Constants.notificationLimit ? .none : .hasNextPage)
  }

  // MARK: - V2 Pagination

  private func fetchNextPageV2(client: Client, selectedType: Models.Notification.NotificationType?)
    async throws
  {
    guard let lastGroup = lastNotificationGroup else { return }

    let results = try await fetchGroupedNotifications(
      client: client,
      sinceId: nil,
      maxId: String(lastGroup.mostRecentNotificationId),
      selectedType: selectedType
    )

    consolidatedNotifications.append(contentsOf: results.consolidated)
    lastNotificationGroup = results.lastGroup

    state = .display(
      notifications: consolidatedNotifications,
      nextPageState: results.hasMore ? .hasNextPage : .none)
  }

  // MARK: - Helper Methods

  func markAsRead() {
    guard let client, let id = consolidatedNotifications.first?.notifications.first?.id else {
      return
    }
    Task {
      do {
        let _: Marker = try await client.post(endpoint: Markers.markNotifications(lastReadId: id))
      } catch {}
    }
  }

  func fetchPolicy() async {
    policy = try? await client?.get(endpoint: Notifications.policy, forceVersion: .v2)
  }

  // MARK: - V2 API Helpers

  private struct GroupedNotificationsFetchResult {
    let consolidated: [ConsolidatedNotification]
    let lastGroup: Models.NotificationGroup?
    let hasMore: Bool
  }

  private func fetchGroupedNotifications(
    client: Client,
    sinceId: String?,
    maxId: String?,
    selectedType: Models.Notification.NotificationType?
  ) async throws -> GroupedNotificationsFetchResult {
    // Determine which types can be grouped
    let groupableTypes = ["favourite", "follow", "reblog"]
    let groupedTypes = selectedType == nil ? groupableTypes : []

    let results: Models.GroupedNotificationsResults = try await client.get(
      endpoint: Notifications.notificationsV2(
        sinceId: sinceId,
        maxId: maxId,
        types: selectedType != nil ? [selectedType!.rawValue] : nil,
        excludeTypes: queryTypes,
        accountId: nil, groupedTypes: groupedTypes,
        expandAccounts: "full"
      ),
      forceVersion: .v2
    )

    // Convert grouped notifications to consolidated format
    var consolidated: [ConsolidatedNotification] = []
    for group in results.notificationGroups {
      let accounts = group.sampleAccountIds.compactMap { accountId in
        results.accounts.first { $0.id == accountId }
      }
      let status = group.statusId.flatMap { statusId in
        results.statuses.first { $0.id == statusId }
      }

      if let notificationType = Models.Notification.NotificationType(rawValue: group.type),
        !accounts.isEmpty
      {
        // For V2 API, we create a simplified consolidated notification
        // The group represents already consolidated notifications
        // We use the most recent notification ID to maintain compatibility
        let placeholderNotification = Models.Notification.placeholder()

        // Parse the date from the group's latestPageNotificationAt
        let createdAt: ServerDate
        if let dateString = group.latestPageNotificationAt {
          // ServerDate can decode from a string directly
          let decoder = JSONDecoder()
          if let data = try? JSONEncoder().encode(dateString),
            let serverDate = try? decoder.decode(ServerDate.self, from: data)
          {
            createdAt = serverDate
          } else {
            createdAt = ServerDate()
          }
        } else {
          createdAt = ServerDate()
        }

        consolidated.append(
          ConsolidatedNotification(
            notifications: [placeholderNotification],  // Use placeholder for ID tracking
            type: notificationType,
            createdAt: createdAt,
            accounts: accounts,
            status: status,
            groupKey: group.groupKey
          ))
      }
    }

    return GroupedNotificationsFetchResult(
      consolidated: consolidated,
      lastGroup: results.notificationGroups.last,
      hasMore: results.notificationGroups.count >= 40
    )
  }

  // MARK: - Streaming Events

  func handleEvent(selectedType: Models.Notification.NotificationType?, event: any StreamEvent) {
    Task {
      // Check if the event is a notification,
      // if it is not already in the list,
      // and if it can be shown (no selected type or the same as the received notification type)
      if lockedAccountId == nil,
        let event = event as? StreamEventNotification,
        !consolidatedNotifications.flatMap(\.notificationIds).contains(event.notification.id),
        selectedType == nil || selectedType?.rawValue == event.notification.type
      {
        let useV2API =
          CurrentInstance.shared.isGroupedNotificationsSupported
          && event.notification.groupKey != nil

        if useV2API {
          await handleStreamEventV2(event: event, selectedType: selectedType)
        } else {
          await handleStreamEventV1(event: event, selectedType: selectedType)
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

  // MARK: - V1 Streaming

  private func handleStreamEventV1(
    event: StreamEventNotification, selectedType: Models.Notification.NotificationType?
  ) async {
    if event.notification.isConsolidable(selectedType: selectedType),
      !consolidatedNotifications.isEmpty
    {
      if let index = consolidatedNotifications.firstIndex(where: {
        $0.type == event.notification.supportedType
          && $0.status?.id == event.notification.status?.id
      }) {
        let latestConsolidatedNotification = consolidatedNotifications.remove(at: index)
        consolidatedNotifications.insert(
          contentsOf: await ([event.notification] + latestConsolidatedNotification.notifications)
            .consolidated(selectedType: selectedType),
          at: 0
        )
      } else {
        let latestConsolidatedNotification = consolidatedNotifications.removeFirst()
        consolidatedNotifications.insert(
          contentsOf: await ([event.notification] + latestConsolidatedNotification.notifications)
            .consolidated(selectedType: selectedType),
          at: 0
        )
      }
    } else {
      // Otherwise, just insert the new notification
      consolidatedNotifications.insert(
        contentsOf: await [event.notification].consolidated(selectedType: selectedType),
        at: 0
      )
    }
  }

  // MARK: - V2 Streaming

  private func handleStreamEventV2(
    event: StreamEventNotification, selectedType: Models.Notification.NotificationType?
  ) async {
    guard let groupKey = event.notification.groupKey else { return }

    // Find existing group with the same group_key
    if let index = consolidatedNotifications.firstIndex(where: { $0.groupKey == groupKey }) {
      // Merge into existing group
      let existingGroup = consolidatedNotifications[index]

      // Add the new account to the group if not already present
      if !existingGroup.accounts.contains(where: { $0.id == event.notification.account.id }) {
        var updatedAccounts = existingGroup.accounts
        updatedAccounts.insert(event.notification.account, at: 0)  // Add new account at the beginning

        // Create updated consolidated notification
        let updatedGroup = ConsolidatedNotification(
          notifications: existingGroup.notifications,
          type: existingGroup.type,
          createdAt: event.notification.createdAt,  // Use the new notification's date
          accounts: updatedAccounts,
          status: existingGroup.status,
          groupKey: groupKey
        )

        // Remove old and insert updated at the top
        consolidatedNotifications.remove(at: index)
        consolidatedNotifications.insert(updatedGroup, at: 0)
      }
    } else {
      // No existing group found, create new one at the top
      let newGroup = ConsolidatedNotification(
        notifications: [event.notification],
        type: event.notification.supportedType ?? .favourite,
        createdAt: event.notification.createdAt,
        accounts: [event.notification.account],
        status: event.notification.status,
        groupKey: groupKey
      )
      consolidatedNotifications.insert(newGroup, at: 0)
    }
  }
}
