import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Lists
import Status
import SwiftUI
import Timeline

@MainActor
extension View {
  func withAppRouter() -> some View {
    navigationDestination(for: RouterDestinations.self) { destination in
      switch destination {
      case let .accountDetail(id):
        AccountDetailView(accountId: id)
      case let .accountDetailWithAccount(account):
        AccountDetailView(account: account)
      case let .accountSettingsWithAccount(account, appAccount):
        AccountSettingsView(account: account, appAccount: appAccount)
      case let .statusDetail(id):
        StatusDetailView(statusId: id)
      case let .conversationDetail(conversation):
        ConversationDetailView(conversation: conversation)
      case let .remoteStatusDetail(url):
        StatusDetailView(remoteStatusURL: url)
      case let .hashTag(tag, accountId):
        TimelineView(timeline: .constant(.hashtag(tag: tag, accountId: accountId)), scrollToTopSignal: .constant(0))
      case let .list(list):
        TimelineView(timeline: .constant(.list(list: list)), scrollToTopSignal: .constant(0))
      case let .following(id):
        AccountsListView(mode: .following(accountId: id))
      case let .followers(id):
        AccountsListView(mode: .followers(accountId: id))
      case let .favoritedBy(id):
        AccountsListView(mode: .favoritedBy(statusId: id))
      case let .rebloggedBy(id):
        AccountsListView(mode: .rebloggedBy(statusId: id))
      }
    }
  }

  func withSheetDestinations(sheetDestinations: Binding<SheetDestinations?>) -> some View {
    sheet(item: sheetDestinations) { destination in
      switch destination {
      case let .replyToStatusEditor(status):
        StatusEditorView(mode: .replyTo(status: status))
          .withEnvironments()
      case let .newStatusEditor(visibility):
        StatusEditorView(mode: .new(visibility: visibility))
          .withEnvironments()
      case let .editStatusEditor(status):
        StatusEditorView(mode: .edit(status: status))
          .withEnvironments()
      case let .quoteStatusEditor(status):
        StatusEditorView(mode: .quote(status: status))
          .withEnvironments()
      case let .mentionStatusEditor(account, visibility):
        StatusEditorView(mode: .mention(account: account, visibility: visibility))
          .withEnvironments()
      case let .listEdit(list):
        ListEditView(list: list)
          .withEnvironments()
      case let .listAddAccount(account):
        ListAddAccountView(account: account)
          .withEnvironments()
      case .addAccount:
        AddAccountView()
          .withEnvironments()
      case .addRemoteLocalTimeline:
        AddRemoteTimelineView()
          .withEnvironments()
      case let .statusEditHistory(status):
        StatusEditHistoryView(statusId: status)
          .withEnvironments()
      case .settings:
        SettingsTabs(popToRootTab: .constant(.settings))
          .withEnvironments()
          .preferredColorScheme(Theme.shared.selectedScheme == .dark ? .dark : .light)
      case .accountPushNotficationsSettings:
        if let subscription = PushNotificationsService.shared.subscriptions.first(where: { $0.account.token == AppAccountsManager.shared.currentAccount.oauthToken }) {
          PushNotificationsView(subscription: subscription)
            .withEnvironments()
        } else {
          EmptyView()
        }
      }
    }
  }

  func withEnvironments() -> some View {
    environmentObject(CurrentAccount.shared)
      .environmentObject(UserPreferences.shared)
      .environmentObject(CurrentInstance.shared)
      .environmentObject(Theme.shared)
      .environmentObject(AppAccountsManager.shared)
      .environmentObject(PushNotificationsService.shared)
  }
}
