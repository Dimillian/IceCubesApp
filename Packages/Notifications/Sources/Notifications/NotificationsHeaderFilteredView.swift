import DesignSystem
import Env
import Models
import SwiftUI

struct NotificationsHeaderFilteredView: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath

  let filteredNotifications: NotificationsPolicy.Summary

  var body: some View {
    if let count = Int(filteredNotifications.pendingNotificationsCount), count > 0 {
      HStack {
        Label("notifications.content-filter.requests.title", systemImage: "archivebox")
          .foregroundStyle(.secondary)
        Spacer()
        Text(filteredNotifications.pendingNotificationsCount)
          .font(.footnote)
          .fontWeight(.semibold)
          .monospacedDigit()
          .foregroundStyle(theme.primaryBackgroundColor)
          .padding(8)
          .background(.secondary)
          .clipShape(Circle())
        Image(systemName: "chevron.right")
          .foregroundStyle(.secondary)
      }
      .onTapGesture {
        routerPath.navigate(to: .notificationsRequests)
      }
      .listRowBackground(theme.secondaryBackgroundColor)
      .listRowInsets(.init(top: 12,
                           leading: .layoutPadding,
                           bottom: 12,
                           trailing: .layoutPadding))
    }
  }
}
