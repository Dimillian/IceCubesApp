import SwiftUI
import Network
import Models
import Shimmer
import DesignSystem

public struct NotificationsListView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = NotificationsViewModel()
  @State private var didAppear: Bool = false
  
  public init() { }
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        if client.isAuth {
          switch viewModel.state {
          case .loading:
            ForEach(Models.Notification.placeholders()) { notification in
              NotificationRowView(notification: notification)
                .redacted(reason: .placeholder)
                .shimmering()
              Divider()
                .padding(.vertical, DS.Constants.dividerPadding)
            }
            
          case let .display(notifications, _):
            ForEach(notifications) { notification in
              NotificationRowView(notification: notification)
              Divider()
                .padding(.vertical, DS.Constants.dividerPadding)
            }
            
          case let .error(error):
            Text(error.localizedDescription)
          }
        } else {
          Text("Please Sign In to see your notifications")
            .font(.title3)
        }
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .padding(.top, DS.Constants.layoutPadding)
    }
    .task {
      if !didAppear {
        didAppear = true
        viewModel.client = client
        await viewModel.fetchNotifications()
      }
    }
    .navigationTitle(Text("Notifications"))
    .navigationBarTitleDisplayMode(.inline)
  }
}
