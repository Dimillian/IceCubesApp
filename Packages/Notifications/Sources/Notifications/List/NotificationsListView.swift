import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct NotificationsListView: View {
  @Environment(\.scenePhase) private var scenePhase

  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentAccount.self) private var account
  @Environment(CurrentInstance.self) private var currentInstance

  @State private var dataSource = NotificationsListDataSource()
  @State private var viewState: NotificationsListState = .loading
  @State private var selectedType: Models.Notification.NotificationType?
  @State private var policy: Models.NotificationsPolicy?
  @State private var isNotificationsPolicyPresented: Bool = false

  let lockedType: Models.Notification.NotificationType?
  let lockedAccountId: String?
  let isLockedType: Bool

  public init(
    lockedType: Models.Notification.NotificationType? = nil,
    lockedAccountId: String? = nil
  ) {
    self.lockedType = lockedType
    self.lockedAccountId = lockedAccountId
    self.isLockedType = lockedType != nil
  }

  public var body: some View {
    List {
      if lockedAccountId == nil, let summary = policy?.summary {
        NotificationsHeaderFilteredView(filteredNotifications: summary)
      }
      notificationsView
        .listSectionSeparator(.hidden, edges: .top)
    }
    .id(account.account?.id)
    .environment(\.defaultMinListRowHeight, 1)
    .listStyle(.plain)
    .toolbar {
      ToolbarItem(placement: .principal) {
        let title =
          lockedType?.menuTitle() ?? selectedType?.menuTitle()
          ?? "notifications.navigation-title"
        if lockedType == nil {
          Text(title)
            .font(.headline)
            .accessibilityRepresentation {
              Menu(title) {}
            }
            .accessibilityAddTraits(.isHeader)
            .accessibilityRemoveTraits(.isButton)
            .accessibilityRespondsToUserInteraction(true)
        } else {
          Text(title)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
        }
      }
    }
    .toolbar {
      if lockedType == nil && lockedAccountId == nil {
        ToolbarTitleMenu {
          Button {
            applyFilter(type: nil)
          } label: {
            Label("notifications.navigation-title", systemImage: "bell.fill")
              .tint(theme.labelColor)
          }
          Divider()
          ForEach(Notification.NotificationType.allCases, id: \.self) { type in
            Button {
              applyFilter(type: type)
            } label: {
              Label {
                Text(type.menuTitle())
              } icon: {
                type.icon(isPrivate: false)
              }
            }
            .tint(theme.labelColor)
          }
          if currentInstance.isNotificationsFilterSupported {
            Divider()
            Button {
              isNotificationsPolicyPresented = true
            } label: {
              Label("notifications.content-filter.title", systemImage: "line.3.horizontal.decrease")
            }
            .tint(theme.labelColor)
          }
          Divider()
          Button {
            routerPath.navigate(to: .conversations)
          } label: {
            Label("Direct Messages", systemImage: "message")
          }
          .tint(theme.labelColor)
        }
      }
    }
    .sheet(isPresented: $isNotificationsPolicyPresented) {
      NotificationsPolicyView()
        .environment(client)
        .environment(theme)
    }
    .navigationBarTitleDisplayMode(.inline)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .task {
      if let lockedType {
        selectedType = lockedType
      }
      await fetchNotifications()
      policy = await dataSource.fetchPolicy(client: client)
    }
    .refreshable {
      SoundEffectManager.shared.playSound(.pull)
      HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
      await fetchNotifications()
      policy = await dataSource.fetchPolicy(client: client)
      HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
      SoundEffectManager.shared.playSound(.refresh)
    }
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent {
        Task {
          await handleStreamEvent(latestEvent)
        }
      }
    }
    .onChange(of: scenePhase) { _, newValue in
      switch newValue {
      case .active:
        Task {
          await fetchNotifications()
        }
      default:
        break
      }
    }
    .onChange(of: client) { oldValue, newValue in
      guard oldValue.id != newValue.id else { return }
      dataSource.reset()
      viewState = .loading
      Task {
        await fetchNotifications()
        policy = await dataSource.fetchPolicy(client: client)
      }
    }
  }

  @ViewBuilder
  private var notificationsView: some View {
    switch viewState {
    case .loading:
      ForEach(ConsolidatedNotification.placeholders()) { notification in
        NotificationRowView(
          notification: notification,
          client: client,
          routerPath: routerPath,
          followRequests: account.followRequests
        )
        .listRowInsets(
          .init(
            top: 12,
            leading: .layoutPadding + 4,
            bottom: 0,
            trailing: .layoutPadding)
        )
        #if os(visionOS)
          .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background))
        #else
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
      }

    case .display(let notifications, let nextPageState):
      if notifications.isEmpty {
        PlaceholderView(
          iconName: "bell.slash",
          title: "notifications.empty.title",
          message: "notifications.empty.message"
        )
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .listSectionSeparator(.hidden)
      } else {
        ForEach(notifications) { notification in
          NotificationRowView(
            notification: notification,
            client: client,
            routerPath: routerPath,
            followRequests: account.followRequests
          )
          .listRowInsets(
            .init(
              top: 12,
              leading: .layoutPadding + 4,
              bottom: 6,
              trailing: .layoutPadding)
          )
          #if os(visionOS)
            .listRowBackground(
              RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(
                  notification.type == .mention && lockedType != .mention
                    ? Material.thick : Material.regular
                ).hoverEffect()
            )
            .listRowHoverEffectDisabled()
          #else
            .listRowBackground(
              notification.type == .mention && lockedType != .mention
                ? theme.secondaryBackgroundColor : theme.primaryBackgroundColor)
          #endif
          .id(notification.id)
        }

        switch nextPageState {
        case .none:
          EmptyView()
        case .hasNextPage:
          NextPageView {
            await fetchNextPage()
          }
          .listRowInsets(
            .init(
              top: .layoutPadding,
              leading: .layoutPadding + 4,
              bottom: .layoutPadding,
              trailing: .layoutPadding)
          )
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #endif
        }
      }

    case .error:
      ErrorView(
        title: "notifications.error.title",
        message: "notifications.error.message",
        buttonTitle: "action.retry"
      ) {
        await fetchNotifications()
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
      .listSectionSeparator(.hidden)
    }
  }
}

extension NotificationsListView {
  private func applyFilter(type: Models.Notification.NotificationType?) {
    selectedType = type
    dataSource.reset()
    viewState = .loading

    Task {
      await fetchNotifications()
    }
  }

  private func fetchNotifications() async {
    do {
      let result = try await dataSource.fetchNotifications(
        client: client,
        selectedType: selectedType,
        lockedAccountId: lockedAccountId
      )

      withAnimation {
        viewState = .display(
          notifications: result.notifications,
          nextPageState: result.nextPageState
        )
      }

      if result.containsFollowRequests {
        await account.fetchFollowerRequests()
      }
    } catch {
      if !Task.isCancelled {
        viewState = .error(error: error)
      }
    }
  }

  private func fetchNextPage() async {
    do {
      let result = try await dataSource.fetchNextPage(
        client: client,
        selectedType: selectedType,
        lockedAccountId: lockedAccountId
      )

      viewState = .display(
        notifications: result.notifications,
        nextPageState: result.nextPageState
      )

      if result.containsFollowRequests {
        await account.fetchFollowerRequests()
      }
    } catch {}
  }

  private func handleStreamEvent(_ event: any StreamEvent) async {
    if let result = await dataSource.handleStreamEvent(
      event: event,
      selectedType: selectedType,
      lockedAccountId: lockedAccountId
    ) {
      withAnimation {
        viewState = .display(
          notifications: result.notifications,
          nextPageState: .hasNextPage
        )
      }

      if result.containsFollowRequest {
        await account.fetchFollowerRequests()
      }
    }
  }
}
