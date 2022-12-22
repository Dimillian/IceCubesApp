import SwiftUI
import Network
import Models
import Shimmer
import DesignSystem

public struct NotificationsListView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = NotificationsViewModel()
  
  public init() { }
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        if client.isAuth {
          Picker("", selection: $viewModel.tab) {
            ForEach(NotificationsViewModel.Tab.allCases, id: \.self) { tab in
              Text(tab.rawValue)
            }
          }
          .pickerStyle(.segmented)
          Group {
            notificationsView
          }
          .padding(.top, 16)
        } else {
          Text("Please Sign In to see your notifications")
            .font(.title3)
        }
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .padding(.top, DS.Constants.layoutPadding)
    }
    .task {
      viewModel.client = client
      await viewModel.fetchNotifications()
    }
    .refreshable {
      Task {
        await viewModel.fetchNotifications()
      }
    }
    .navigationTitle(Text("Notifications"))
    .navigationBarTitleDisplayMode(.inline)
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
          .padding(.vertical, DS.Constants.dividerPadding)
      }
      
    case let .display(notifications, nextPageState):
      ForEach(notifications) { notification in
        NotificationRowView(notification: notification)
        Divider()
          .padding(.vertical, DS.Constants.dividerPadding)
      }
      
      switch nextPageState {
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
