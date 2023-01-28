import DesignSystem
import EmojiText
import Env
import Models
import Status
import SwiftUI

struct NotificationRowView: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var routerPath: RouterPath
  @Environment(\.redactionReasons) private var reasons

  let notification: ConsolidatedNotification

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      if notification.accounts.count == 1 {
        makeAvatarView(type: notification.type)
      } else {
        makeNotificationIconView(type: notification.type)
          .frame(width: AvatarView.Size.status.size.width,
                 height: AvatarView.Size.status.size.height)
      }
      VStack(alignment: .leading, spacing: 2) {
        makeMainLabel(type: notification.type)
        makeContent(type: notification.type)
        if notification.type == .follow_request,
           currentAccount.followRequests.map(\.id).contains(notification.accounts[0].id)
        {
          FollowRequestButtons(account: notification.accounts[0])
        }
      }
    }
  }

  private func makeAvatarView(type: Models.Notification.NotificationType) -> some View {
    ZStack(alignment: .topLeading) {
      AvatarView(url: notification.accounts[0].avatar)
      makeNotificationIconView(type: type)
        .offset(x: -8, y: -8)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routerPath.navigate(to: .accountDetailWithAccount(account: notification.accounts[0]))
    }
  }

  private func makeNotificationIconView(type: Models.Notification.NotificationType) -> some View {
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
  }

  private func makeMainLabel(type: Models.Notification.NotificationType) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      if notification.accounts.count > 1 {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 8) {
            ForEach(notification.accounts) { account in
              AvatarView(url: account.avatar)
                .contentShape(Rectangle())
                .onTapGesture {
                  routerPath.navigate(to: .accountDetailWithAccount(account: account))
                }
            }
          }
          .padding(.leading, 1)
          .frame(height: AvatarView.Size.status.size.height + 2)
        }.offset(y: -1)
      }
      HStack(spacing: 0) {
        EmojiTextApp(.init(stringValue: notification.accounts[0].safeDisplayName),
                     emojis: notification.accounts[0].emojis,
                     append: {
                       (notification.accounts.count > 1
                         ? Text("notifications-others-count \(notification.accounts.count - 1)")
                         .font(.scaledSubheadline)
                         .fontWeight(.regular)
                         : Text(" ")) +
                         Text(type.label(count: notification.accounts.count))
                         .font(.scaledSubheadline)
                         .fontWeight(.regular) +
                         Text(" ⸱ ")
                         .font(.scaledFootnote)
                         .fontWeight(.regular)
                         .foregroundColor(.gray) +
                         Text(notification.createdAt.relativeFormatted)
                         .font(.scaledFootnote)
                         .fontWeight(.regular)
                         .foregroundColor(.gray)
                     })
                     .font(.scaledSubheadline)
                     .fontWeight(.semibold)
        if let status = notification.status, notification.type == .mention {
          Group {
            Text(" ⸱ ")
            Text(Image(systemName: status.visibility.iconName))
          }
          .font(.scaledFootnote)
          .fontWeight(.regular)
          .foregroundColor(.gray)
        }
        Spacer()
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routerPath.navigate(to: .accountDetailWithAccount(account: notification.accounts[0]))
    }
  }

  @ViewBuilder
  private func makeContent(type: Models.Notification.NotificationType) -> some View {
    if let status = notification.status {
      HStack {
        if type == .mention {
          StatusRowView(viewModel: .init(status: status, isCompact: true, showActions: true))
        } else {
          StatusRowView(viewModel: .init(status: status, isCompact: true, showActions: false))
            .lineLimit(4)
            .foregroundColor(.gray)
        }
        Spacer()
      }
    } else {
      Group {
        Text("@\(notification.accounts[0].acct)")
          .font(.scaledCallout)
          .foregroundColor(.gray)

        if type == .follow {
          EmojiTextApp(notification.accounts[0].note,
                       emojis: notification.accounts[0].emojis)
            .lineLimit(3)
            .font(.scaledCallout)
            .foregroundColor(.gray)
            .environment(\.openURL, OpenURLAction { url in
              routerPath.handle(url: url)
            })
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        routerPath.navigate(to: .accountDetailWithAccount(account: notification.accounts[0]))
      }
    }
  }
}

struct NotificationRowView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationRowView(notification: .placeholder())
  }
}
