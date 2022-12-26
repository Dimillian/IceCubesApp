import SwiftUI
import Models
import DesignSystem
import Status
import Env

struct NotificationRowView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var routeurPath: RouterPath
  @Environment(\.redactionReasons) private var reasons
    
  let notification: Models.Notification
  
  var body: some View {
    if let type = notification.supportedType {
      HStack(alignment: .top, spacing: 8) {
        makeAvatarView(type: type)
        VStack(alignment: .leading, spacing: 2) {
          makeMainLabel(type: type)
          makeContent(type: type)
        }
      }
    } else {
      EmptyView()
    }
  }
  
  private func makeAvatarView(type: Models.Notification.NotificationType) -> some View {
    ZStack(alignment: .topLeading) {
      AvatarView(url: notification.account.avatar)
      ZStack(alignment: .center) {
        Circle()
          .strokeBorder(Color.white, lineWidth: 1)
          .background(Circle().foregroundColor(theme.tintColor))
          .frame(width: 24, height: 24)
        
        Image(systemName: type.iconName())
          .resizable()
          .frame(width: 12, height: 12)
          .foregroundColor(.white)
      }
      .offset(x: -14, y: -4)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routeurPath.navigate(to: .accountDetailWithAccount(account: notification.account))
    }
  }
  
  private func makeMainLabel(type: Models.Notification.NotificationType) -> some View {
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
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routeurPath.navigate(to: .accountDetailWithAccount(account: notification.account))
    }
  }
  
  @ViewBuilder
  private func makeContent(type: Models.Notification.NotificationType) -> some View {
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
      Group {
        Text("@\(notification.account.acct)")
          .font(.callout)
          .foregroundColor(.gray)
        
        if type == .follow {
          Text(notification.account.note.asSafeAttributedString)
            .lineLimit(3)
            .font(.callout)
            .foregroundColor(.gray)
            .environment(\.openURL, OpenURLAction { url in
              routeurPath.handle(url: url)
            })
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        routeurPath.navigate(to: .accountDetailWithAccount(account: notification.account))
      }
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
  
  func iconName() -> String {
    switch self {
    case .status:
      return "pencil"
    case .mention:
      return "at"
    case .reblog:
      return "arrow.left.arrow.right.circle.fill"
    case .follow, .follow_request:
      return "person.fill.badge.plus"
    case .favourite:
      return "star.fill"
    case .poll:
      return "chart.bar.fill"
    case .update:
      return "pencil.line"
    }
  }
}

struct NotificationRowView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationRowView(notification: .placeholder())
  }
}
