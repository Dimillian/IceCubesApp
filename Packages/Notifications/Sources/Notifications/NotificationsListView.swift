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
  @StateObject private var viewModel = NotificationsViewModel()

  let lockedType: Models.Notification.NotificationType?

  public init(lockedType: Models.Notification.NotificationType?) {
    self.lockedType = lockedType
  }

  public var body: some View {
    ScrollView {
      LazyVStack {
        notificationsView
          .frame(maxWidth: .maxColumnWidth)
      }
      .padding(.top, .layoutPadding + 16)
      .background(theme.primaryBackgroundColor)
    }
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
          .padding(.leading, .layoutPadding + 4)
          .padding(.trailing, .layoutPadding)
          .padding(.top, 6)
          .padding(.bottom, 2)
          .shimmering()
        Divider()
          .padding(.vertical, .dividerPadding)
      }

    case let .display(notifications, nextPageState):
      if notifications.isEmpty {
        EmptyView(iconName: "bell.slash",
                  title: "notifications.empty.title",
                  message: "notifications.empty.message")
      } else {
        ForEach(notifications) { notification in
          NotificationRowView(notification: notification)
            .padding(.leading, .layoutPadding + 4)
            .padding(.trailing, .layoutPadding)
            .padding(.top, 6)
            .padding(.bottom, 2)
          Divider()
            .padding(.vertical, .dividerPadding)
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
    }
  }

  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}
