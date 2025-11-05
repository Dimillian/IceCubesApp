import Env
import Foundation
import Models
import NetworkClient

@MainActor
public final class NotificationsListDataSource {
  enum Constants {
    static let notificationLimit: Int = 30
  }

  // Internal state
  private var consolidatedNotifications: [ConsolidatedNotification] = []
  private var lastNotificationGroup: Models.NotificationGroup?

  public init() {}

  // MARK: - Public Methods

  public func reset() {
    consolidatedNotifications = []
    lastNotificationGroup = nil
  }

  public struct FetchResult {
    let notifications: [ConsolidatedNotification]
    let nextPageState: NotificationsListState.PagingState
    let containsFollowRequests: Bool
  }

  public func fetchNotifications(
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?,
    lockedAccountId: String?
  ) async throws -> FetchResult {
    let useV2API = CurrentInstance.shared.isGroupedNotificationsSupported && lockedAccountId == nil

    if consolidatedNotifications.isEmpty {
      // Initial load
      if useV2API {
        try await fetchNotificationsV2(client: client, selectedType: selectedType)
      } else {
        try await fetchNotificationsV1(
          client: client,
          selectedType: selectedType,
          lockedAccountId: lockedAccountId
        )
      }
    } else {
      // Pull to refresh
      if useV2API {
        try await refreshNotificationsV2(client: client, selectedType: selectedType)
      } else {
        try await refreshNotificationsV1(
          client: client,
          selectedType: selectedType,
          lockedAccountId: lockedAccountId
        )
      }
    }

    markAsRead(client: client)

    let nextPageState: NotificationsListState.PagingState =
      consolidatedNotifications.isEmpty
      ? .none
      : (lastNotificationGroup != nil
        || consolidatedNotifications.count >= Constants.notificationLimit
        ? .hasNextPage : .none)

    return FetchResult(
      notifications: consolidatedNotifications,
      nextPageState: nextPageState,
      containsFollowRequests: consolidatedNotifications.contains { $0.type == .follow_request }
    )
  }

  public func fetchNextPage(
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?,
    lockedAccountId: String?
  ) async throws -> FetchResult {
    let useV2API = CurrentInstance.shared.isGroupedNotificationsSupported && lockedAccountId == nil

    if useV2API {
      try await fetchNextPageV2(client: client, selectedType: selectedType)
    } else {
      try await fetchNextPageV1(
        client: client,
        selectedType: selectedType,
        lockedAccountId: lockedAccountId
      )
    }

    let hasMore =
      useV2API
      ? (lastNotificationGroup != nil)
      : (consolidatedNotifications.count % Constants.notificationLimit == 0)

    return FetchResult(
      notifications: consolidatedNotifications,
      nextPageState: hasMore ? .hasNextPage : .none,
      containsFollowRequests: consolidatedNotifications.contains { $0.type == .follow_request }
    )
  }

  public func fetchPolicy(client: MastodonClient) async -> Models.NotificationsPolicy? {
    try? await client.get(endpoint: Notifications.policy, forceVersion: .v2)
  }

  // MARK: - V1 API Methods

  private func fetchNotificationsV1(
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?,
    lockedAccountId: String?
  ) async throws {
    let notifications: [Models.Notification]
    let queryTypes = queryTypes(for: selectedType)

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
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?,
    lockedAccountId: String?
  ) async throws {
    guard let firstId = consolidatedNotifications.first?.id else { return }

    var newNotifications: [Models.Notification] = await fetchNewPages(
      client: client,
      minId: firstId,
      maxPages: 10,
      selectedType: selectedType,
      lockedAccountId: lockedAccountId
    )
    newNotifications = newNotifications.filter { notification in
      !consolidatedNotifications.contains(where: { $0.id == notification.id })
    }

    consolidatedNotifications.insert(
      contentsOf: await newNotifications.consolidated(selectedType: selectedType),
      at: 0
    )
  }

  private func fetchNextPageV1(
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?,
    lockedAccountId: String?
  ) async throws {
    guard let lastId = consolidatedNotifications.last?.notificationIds.last else { return }

    let queryTypes = queryTypes(for: selectedType)
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
  }

  private func fetchNewPages(
    client: MastodonClient,
    minId: String,
    maxPages: Int,
    selectedType: Models.Notification.NotificationType?,
    lockedAccountId: String?
  ) async -> [Models.Notification] {
    guard lockedAccountId == nil else { return [] }

    var pagesLoaded = 0
    var allNotifications: [Models.Notification] = []
    var latestMinId = minId
    let queryTypes = queryTypes(for: selectedType)

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

  // MARK: - V2 API Methods

  private func fetchNotificationsV2(
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?
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
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?
  ) async throws {
    guard let firstGroup = consolidatedNotifications.first else { return }
    let results = try await fetchGroupedNotifications(
      client: client,
      sinceId: firstGroup.mostRecentNotificationId,
      maxId: nil,
      selectedType: selectedType
    )

    mergeV2Notifications(results.consolidated)
  }

  private func fetchNextPageV2(
    client: MastodonClient,
    selectedType: Models.Notification.NotificationType?
  ) async throws {
    guard let lastGroup = lastNotificationGroup else { return }

    let results = try await fetchGroupedNotifications(
      client: client,
      sinceId: nil,
      maxId: String(lastGroup.mostRecentNotificationId),
      selectedType: selectedType
    )

    consolidatedNotifications.append(contentsOf: results.consolidated)
    lastNotificationGroup = results.lastGroup
  }

  // MARK: - Stream Event Handling

  public struct StreamEventResult {
    let notifications: [ConsolidatedNotification]
    let containsFollowRequest: Bool
  }

  public func handleStreamEvent(
    event: any StreamEvent,
    selectedType: Models.Notification.NotificationType?,
    lockedAccountId: String?
  ) async -> StreamEventResult? {
    guard lockedAccountId == nil,
      let event = event as? StreamEventNotification,
      !consolidatedNotifications.flatMap(\.notificationIds).contains(event.notification.id),
      selectedType == nil || selectedType?.rawValue == event.notification.type
    else { return nil }

    let useV2API =
      CurrentInstance.shared.isGroupedNotificationsSupported
      && event.notification.groupKey != nil

    if useV2API {
      await handleStreamEventV2(event: event, selectedType: selectedType)
    } else {
      await handleStreamEventV1(event: event, selectedType: selectedType)
    }

    return StreamEventResult(
      notifications: consolidatedNotifications,
      containsFollowRequest: event.notification.supportedType == .follow_request
    )
  }

  private func handleStreamEventV1(
    event: StreamEventNotification,
    selectedType: Models.Notification.NotificationType?
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
      consolidatedNotifications.insert(
        contentsOf: await [event.notification].consolidated(selectedType: selectedType),
        at: 0
      )
    }
  }

  private func handleStreamEventV2(
    event: StreamEventNotification,
    selectedType: Models.Notification.NotificationType?
  ) async {
    guard let groupKey = event.notification.groupKey else { return }

    let newGroup = ConsolidatedNotification(
      notifications: [event.notification],
      mostRecentNotificationId: event.notification.id,
      type: event.notification.supportedType ?? .favourite,
      createdAt: event.notification.createdAt,
      accounts: [event.notification.account],
      status: event.notification.status,
      groupKey: groupKey
    )

    mergeV2Notifications([newGroup])
  }

  // MARK: - Helper Methods

  private func queryTypes(for selectedType: Models.Notification.NotificationType?) -> [String]? {
    if let selectedType {
      var excludedTypes = Models.Notification.NotificationType.allCases
      excludedTypes.removeAll(where: { $0 == selectedType })
      return excludedTypes.map(\.rawValue)
    }
    return nil
  }

  private func markAsRead(client: MastodonClient) {
    guard let id = consolidatedNotifications.first?.mostRecentNotificationId else { return }
    Task {
      do {
        let _: Marker = try await client.post(endpoint: Markers.markNotifications(lastReadId: id))
      } catch {}
    }
  }

  private func mergeV2Notifications(_ newGroups: [ConsolidatedNotification]) {
    for newGroup in newGroups.reversed() {
      if let groupKey = newGroup.groupKey {
        if let existingIndex = consolidatedNotifications.firstIndex(where: {
          $0.groupKey == groupKey
        }) {
          let existingGroup = consolidatedNotifications[existingIndex]
          var updatedAccounts = existingGroup.accounts

          for newAccount in newGroup.accounts {
            if !updatedAccounts.contains(where: { $0.id == newAccount.id }) {
              updatedAccounts.insert(newAccount, at: 0)
            }
          }

          let updatedGroup = ConsolidatedNotification(
            notifications: existingGroup.notifications,
            mostRecentNotificationId: newGroup.mostRecentNotificationId,
            type: existingGroup.type,
            createdAt: newGroup.createdAt,
            accounts: updatedAccounts,
            status: existingGroup.status,
            groupKey: groupKey
          )

          consolidatedNotifications.remove(at: existingIndex)
          consolidatedNotifications.insert(updatedGroup, at: 0)
        } else {
          consolidatedNotifications.insert(newGroup, at: 0)
        }
      } else {
        consolidatedNotifications.insert(newGroup, at: 0)
      }
    }
  }

  private struct GroupedNotificationsFetchResult {
    let consolidated: [ConsolidatedNotification]
    let lastGroup: Models.NotificationGroup?
    let hasMore: Bool
  }

  private func fetchGroupedNotifications(
    client: MastodonClient,
    sinceId: String?,
    maxId: String?,
    selectedType: Models.Notification.NotificationType?
  ) async throws -> GroupedNotificationsFetchResult {
    let groupableTypes = ["favourite", "follow", "reblog"]
    let groupedTypes = selectedType == nil ? groupableTypes : []
    let queryTypes = queryTypes(for: selectedType)

    let results: Models.GroupedNotificationsResults = try await client.get(
      endpoint: Notifications.notificationsV2(
        sinceId: sinceId,
        maxId: maxId,
        types: selectedType != nil ? [selectedType!.rawValue] : nil,
        excludeTypes: queryTypes,
        accountId: nil,
        groupedTypes: groupedTypes,
        expandAccounts: "full"
      ),
      forceVersion: .v2
    )

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
        consolidated.append(
          ConsolidatedNotification(
            notifications: [],
            mostRecentNotificationId: String(group.mostRecentNotificationId),
            type: notificationType,
            createdAt: group.latestPageNotificationAt,
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
}
