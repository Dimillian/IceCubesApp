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
        Text(notification.account.safeDisplayName)
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
      HStack {
        StatusRowView(viewModel: .init(status: status, isCompact: true))
          .foregroundColor(type == .mention ? theme.labelColor : .gray)
        Spacer()
      }
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

struct NotificationRowView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationRowView(notification: .placeholder())
  }
}
