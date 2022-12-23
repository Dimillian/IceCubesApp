import SwiftUI
import Models
import DesignSystem
import Status
import Env

struct NotificationRowView: View {
  @EnvironmentObject private var routeurPath: RouterPath
  @Environment(\.redactionReasons) private var reasons
    
  let notification: Models.Notification
  
  var body: some View {
    if let type = notification.supportedType {
      HStack(alignment: .top, spacing: 8) {
        AvatarView(url: notification.account.avatar)
          .onTapGesture {
            routeurPath.navigate(to: .accountDetailWithAccount(account: notification.account))
        }
        VStack(alignment: .leading, spacing: 0) {
          HStack(spacing: 0) {
            Text(notification.account.displayName)
              .font(.subheadline)
              .fontWeight(.semibold) +
            Text(" ") +
            Text(type.label())
              .font(.subheadline) +
            Text(" ⸱ ")
              .font(.footnote)
              .foregroundColor(.gray) +
            Text(notification.createdAt.formatted)
              .font(.footnote)
              .foregroundColor(.gray)
            Spacer()
          }
          if let status = notification.status {
            StatusRowView(viewModel: .init(status: status, isEmbed: true))
              .padding(8)
              .background(Color.gray.opacity(0.10))
              .overlay(
                RoundedRectangle(cornerRadius: 4)
                  .stroke(.gray.opacity(0.35), lineWidth: 1)
              )
              .padding(.top, 8)
          } else {
            Text(notification.account.acct)
              .font(.callout)
              .foregroundColor(.gray)
          }
        }
      }
    } else {
      EmptyView()
    }
  }
}

extension Models.Notification.NotificationType {
  func label() -> String {
    switch self {
    case .status:
      return "posted a status"
    case .mention:
      return "mentionned you"
    case .reblog:
      return "boosted"
    case .follow:
      return "followed you"
    case .follow_request:
      return "request to follow you"
    case .favourite:
      return "starred"
    case .poll:
      return "poll ended"
    case .update:
      return "has been edited"
    }
  }
}

struct NotificationRowView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationRowView(notification: .placeholder())
  }
}
