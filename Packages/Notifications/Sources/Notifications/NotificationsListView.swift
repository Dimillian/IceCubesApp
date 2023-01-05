import SwiftUI
import Network
import Models
import Shimmer
import DesignSystem
import Env

public struct NotificationsListView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = NotificationsViewModel()
  
  public init() { }
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        Group {
          notificationsView
        }
        .padding(.top, 16)
      }
      .padding(.horizontal, .layoutPadding)
      .padding(.top, .layoutPadding)
    }
    .navigationTitle(viewModel.selectedType?.menuTitle() ?? "All Notifications")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarTitleMenu {
        Button {
          viewModel.selectedType = nil
        } label: {
          Label("All Notifications", systemImage: "bell.fill")
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
    .background(theme.primaryBackgroundColor)
    .task {
      viewModel.client = client
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
  }
  
  @ViewBuilder
  private var notificationsView: some View {
    switch viewModel.state {
    case .loading:
      ForEach(Models.Notification.placeholders()) { notification in
        NotificationRowView(notification: notification)
          .redacted(reason: .placeholder)
          .shimmering()
        Divider()
          .padding(.vertical, .dividerPadding)
      }
      
    case let .display(notifications, nextPageState):
      ForEach(notifications) { notification in
        NotificationRowView(notification: notification)
        Divider()
          .padding(.vertical, .dividerPadding)
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
      
    case let .error(error):
      Text(error.localizedDescription)
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
