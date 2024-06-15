import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Explore
import LinkPresentation
import Lists
import MediaUI
import Models
import Notifications
import StatusKit
import SwiftUI
import Timeline

@MainActor
extension View {
  func withAppRouter() -> some View {
    navigationDestination(for: RouterDestination.self) { destination in
      switch destination {
      case let .accountDetail(id):
        AccountDetailView(accountId: id, scrollToTopSignal: .constant(0))
      case let .accountDetailWithAccount(account):
        AccountDetailView(account: account, scrollToTopSignal: .constant(0))
      case let .accountSettingsWithAccount(account, appAccount):
        AccountSettingsView(account: account, appAccount: appAccount)
      case let .statusDetail(id):
        StatusDetailView(statusId: id)
      case let .statusDetailWithStatus(status):
        StatusDetailView(status: status)
      case let .remoteStatusDetail(url):
        StatusDetailView(remoteStatusURL: url)
      case let .conversationDetail(conversation):
        ConversationDetailView(conversation: conversation)
      case let .hashTag(tag, accountId):
        TimelineView(timeline: .constant(.hashtag(tag: tag, accountId: accountId)),
                     pinnedFilters: .constant([]),
                     selectedTagGroup: .constant(nil),
                     scrollToTopSignal: .constant(0),
                     canFilterTimeline: false)
      case let .list(list):
        TimelineView(timeline: .constant(.list(list: list)),
                     pinnedFilters: .constant([]),
                     selectedTagGroup: .constant(nil),
                     scrollToTopSignal: .constant(0),
                     canFilterTimeline: false)
      case let .following(id):
        AccountsListView(mode: .following(accountId: id))
      case let .followers(id):
        AccountsListView(mode: .followers(accountId: id))
      case let .favoritedBy(id):
        AccountsListView(mode: .favoritedBy(statusId: id))
      case let .rebloggedBy(id):
        AccountsListView(mode: .rebloggedBy(statusId: id))
      case let .accountsList(accounts):
        AccountsListView(mode: .accountsList(accounts: accounts))
      case .trendingTimeline:
        TimelineView(timeline: .constant(.trending),
                     pinnedFilters: .constant([]),
                     selectedTagGroup: .constant(nil),
                     scrollToTopSignal: .constant(0),
                     canFilterTimeline: false)
      case let .trendingLinks(cards):
        TrendingLinksListView(cards: cards)
      case let .tagsList(tags):
        TagsListView(tags: tags)
      case .notificationsRequests:
        NotificationsRequestsListView()
      case let .notificationForAccount(accountId):
        NotificationsListView(lockedType: nil,
                              lockedAccountId: accountId,
                              scrollToTopSignal: .constant(0))
      case .blockedAccounts:
        AccountsListView(mode: .blocked)
      case .mutedAccounts:
        AccountsListView(mode: .muted)
      }
    }
  }

  func withSheetDestinations(sheetDestinations: Binding<SheetDestination?>) -> some View {
    sheet(item: sheetDestinations) { destination in
      switch destination {
      case let .replyToStatusEditor(status):
        StatusEditor.MainView(mode: .replyTo(status: status))
          .withEnvironments()
      case let .newStatusEditor(visibility):
        StatusEditor.MainView(mode: .new(text: nil, visibility: visibility))
          .withEnvironments()
      case let .prefilledStatusEditor(text, visibility):
        StatusEditor.MainView(mode: .new(text: text, visibility: visibility))
          .withEnvironments()
      case let .imageURL(urls, visibility):
        StatusEditor.MainView(mode: .imageURL(urls: urls, visibility: visibility))
          .withEnvironments()
      case let .editStatusEditor(status):
        StatusEditor.MainView(mode: .edit(status: status))
          .withEnvironments()
      case let .quoteStatusEditor(status):
        StatusEditor.MainView(mode: .quote(status: status))
          .withEnvironments()
      case let .quoteLinkStatusEditor(link):
        StatusEditor.MainView(mode: .quoteLink(link: link))
          .withEnvironments()
      case let .mentionStatusEditor(account, visibility):
        StatusEditor.MainView(mode: .mention(account: account, visibility: visibility))
          .withEnvironments()
      case .listCreate:
        ListCreateView()
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
      case .addTagGroup:
        EditTagGroupView()
          .withEnvironments()
      case let .statusEditHistory(status):
        StatusEditHistoryView(statusId: status)
          .withEnvironments()
      case .settings:
        SettingsTabs(popToRootTab: .constant(.settings), isModal: true)
          .withEnvironments()
          .preferredColorScheme(Theme.shared.selectedScheme == .dark ? .dark : .light)
      case .accountPushNotficationsSettings:
        if let subscription = PushNotificationsService.shared.subscriptions.first(where: { $0.account.token == AppAccountsManager.shared.currentAccount.oauthToken }) {
          NavigationSheet { PushNotificationsView(subscription: subscription) }
            .withEnvironments()
        } else {
          EmptyView()
        }
      case .about:
        NavigationSheet { AboutView() }
          .withEnvironments()
      case .support:
        NavigationSheet { SupportAppView() }
          .withEnvironments()
      case let .report(status):
        ReportView(status: status)
          .withEnvironments()
      case let .shareImage(image, status):
        ActivityView(image: image, status: status)
          .withEnvironments()
      case let .editTagGroup(tagGroup, onSaved):
        EditTagGroupView(tagGroup: tagGroup, onSaved: onSaved)
          .withEnvironments()
      case .timelineContentFilter:
        NavigationSheet { TimelineContentFilterView() }
          .presentationDetents([.medium])
          .presentationBackground(.thinMaterial)
          .withEnvironments()
      case .accountEditInfo:
        EditAccountView()
          .withEnvironments()
      case .accountFiltersList:
        FiltersListView()
          .withEnvironments()
      }
    }
  }

  func withEnvironments() -> some View {
    environment(CurrentAccount.shared)
      .environment(UserPreferences.shared)
      .environment(CurrentInstance.shared)
      .environment(Theme.shared)
      .environment(AppAccountsManager.shared)
      .environment(PushNotificationsService.shared)
      .environment(AppAccountsManager.shared.currentClient)
      .environment(QuickLook.shared)
  }

  func withModelContainer() -> some View {
    modelContainer(for: [
      Draft.self,
      LocalTimeline.self,
      TagGroup.self,
      RecentTag.self,
    ])
  }
}

struct ActivityView: UIViewControllerRepresentable {
  let image: UIImage
  let status: Status

  class LinkDelegate: NSObject, UIActivityItemSource {
    let image: UIImage
    let status: Status

    init(image: UIImage, status: Status) {
      self.image = image
      self.status = status
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
      let imageProvider = NSItemProvider(object: image)
      let metadata = LPLinkMetadata()
      metadata.imageProvider = imageProvider
      metadata.title = status.reblog?.content.asRawText ?? status.content.asRawText
      return metadata
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
      image
    }

    func activityViewController(_: UIActivityViewController,
                                itemForActivityType _: UIActivity.ActivityType?) -> Any?
    {
      nil
    }
  }

  func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, LinkDelegate(image: image, status: status)],
                             applicationActivities: nil)
  }

  func updateUIViewController(_: UIActivityViewController, context _: UIViewControllerRepresentableContext<ActivityView>) {}
}

extension URL: Identifiable {
  public var id: String {
    absoluteString
  }
}
