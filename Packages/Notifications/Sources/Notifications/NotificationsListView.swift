import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

public struct NotificationsListView: View {
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var account: CurrentAccount
  @StateObject private var viewModel = NotificationsViewModel()

  let lockedType: Models.Notification.NotificationType?

  public init(lockedType: Models.Notification.NotificationType?) {
    self.lockedType = lockedType
  }

  public var body: some View {
    List {
      topPaddingView
      notificationsView
    }
    .id(account.account?.id)
    .environment(\.defaultMinListRowHeight, 1)
    .listStyle(.plain)
    .navigationTitle(lockedType?.menuTitle() ?? viewModel.selectedType?.menuTitle() ?? "notifications.navigation-title")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if lockedType == nil {
        ToolbarTitleMenu {
          Button {
            viewModel.selectedType = nil
          } label: {
            Label("notifications.navigation-title", systemImage: "bell.fill")
          }
          Divider()
          ForEach(Notification.NotificationType.allCases, id: \.self) { type in
            Button {
              viewModel.selectedType = type
            } label: {
              Label(type.menuTitle(), systemImage: type.iconName())
            }
          }
        }
      }
    }
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    .task {
      viewModel.client = client
      viewModel.currentAccount = account
      if let lockedType {
        viewModel.selectedType = lockedType
      }
      await viewModel.fetchNotifications()
    }
    .refreshable {
      await viewModel.fetchNotifications()
    }
    .onChange(of: watcher.latestEvent?.id, perform: { _ in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent)
      }
    })
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .active:
        Task {
          await viewModel.fetchNotifications()
        }
      default:
        break
      }
    })
  }

  @ViewBuilder
  private var notificationsView: some View {
    switch viewModel.state {
    case .loading:
      ForEach(ConsolidatedNotification.placeholders()) { notification in
        NotificationRowView(notification: notification)
          .redacted(reason: .placeholder)
          .listRowInsets(.init(top: 12,
                               leading: .layoutPadding + 4,
                               bottom: 12,
                               trailing: .layoutPadding))
          .listRowBackground(theme.primaryBackgroundColor)
          .redacted(reason: .placeholder)
      }

    case let .display(notifications, nextPageState):
      if notifications.isEmpty {
        EmptyView(iconName: "bell.slash",
                  title: "notifications.empty.title",
                  message: "notifications.empty.message")
        .listRowBackground(theme.primaryBackgroundColor)
        .listSectionSeparator(.hidden)
      } else {
        ForEach(notifications) { notification in
          NotificationRowView(notification: notification)
            .listRowInsets(.init(top: 12,
                                 leading: .layoutPadding + 4,
                                 bottom: 12,
                                 trailing: .layoutPadding))
            .listRowBackground(notification.type == .mention && lockedType != .mention ?
              theme.secondaryBackgroundColor : theme.primaryBackgroundColor)
        }
      }

      switch nextPageState {
      case .none:
        EmptyView()
      case .hasNextPage:
        loadingRow
          .onAppear {
            Task {
              await viewModel.fetchNextPage()
            }
          }
      case .loadingNextPage:
        loadingRow
      }

    case .error:
      ErrorView(title: "notifications.error.title",
                message: "notifications.error.message",
                buttonTitle: "action.retry") {
        Task {
          await viewModel.fetchNotifications()
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .listSectionSeparator(.hidden)
    }
  }

  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .listRowInsets(.init(top: .layoutPadding,
                         leading: .layoutPadding + 4,
                         bottom: .layoutPadding,
                         trailing: .layoutPadding))
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var topPaddingView: some View {
    HStack {}
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
      .listRowInsets(.init())
      .frame(height: .layoutPadding)
  }
}
