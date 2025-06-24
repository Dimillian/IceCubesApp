import AppAccount
import DesignSystem
import EmojiText
import Env
import Models
import NukeUI
import SwiftUI

@MainActor
struct AccountDetailHeaderView: View {
  enum Constants {
    static let headerHeight: CGFloat = 200
  }

  @Environment(\.openWindow) private var openWindow
  @Environment(Theme.self) private var theme
  @Environment(QuickLook.self) private var quickLook
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(StreamWatcher.self) private var watcher
  @Environment(AppAccountsManager.self) private var appAccount
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isSupporter) private var isSupporter: Bool
  @Environment(\.openURL) private var openURL
  @Environment(\.colorScheme) private var colorScheme

  let account: Account
  let relationship: Relationship?
  let fields: [Account.Field]
  @Binding var followButtonViewModel: FollowButtonViewModel?
  @Binding var translation: Translation?
  @Binding var isLoadingTranslation: Bool
  let isCurrentUser: Bool
  let accountId: String
  let scrollViewProxy: ScrollViewProxy?

  var body: some View {
    VStack(alignment: .leading) {
      AccountHeaderImageView(account: account, relationship: relationship)
      accountInfoView
      Spacer()
    }
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent,
        let latestEvent = latestEvent as? StreamEventNotification
      {
        if latestEvent.notification.account.id == accountId {
          Task {
            try? await followButtonViewModel?.refreshRelationship()
          }
        }
      }
    }
  }

  private var accountAvatarView: some View {
    HStack {
      AccountAvatarView(account: account, isCurrentUser: isCurrentUser)

      Spacer()

      AccountStatsView(account: account, scrollViewProxy: scrollViewProxy)
    }
  }

  private var accountInfoView: some View {
    Group {
      accountAvatarView

      AccountInfoView(
        account: account,
        relationship: relationship,
        isCurrentUser: isCurrentUser,
        followButtonViewModel: $followButtonViewModel,
        translation: $translation,
        isLoadingTranslation: $isLoadingTranslation
      )

      AccountFieldsView(fields: fields, account: account)
    }
    .padding(.horizontal, .layoutPadding)
    .offset(y: -40)
  }

}

struct AccountDetailHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailHeaderView(
      account: .placeholder(),
      relationship: nil,
      fields: [],
      followButtonViewModel: .constant(nil),
      translation: .constant(nil),
      isLoadingTranslation: .constant(false),
      isCurrentUser: false,
      accountId: "123",
      scrollViewProxy: nil)
  }
}
