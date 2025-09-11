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
      case .accountDetail(let id):
        AccountDetailView(accountId: id)
      case .accountDetailWithAccount(let account):
        AccountDetailView(account: account)
      case .accountSettingsWithAccount(let account, let appAccount):
        AccountSettingsView(account: account, appAccount: appAccount)
      case .accountMediaGridView(let account, let initialMedia):
        AccountDetailMediaGridView(account: account, initialMediaStatuses: initialMedia)
      case .statusDetail(let id):
        StatusDetailView(statusId: id)
      case .statusDetailWithStatus(let status):
        StatusDetailView(status: status)
      case .remoteStatusDetail(let url):
        StatusDetailView(remoteStatusURL: url)
      case .conversationDetail(let conversation):
        ConversationDetailView(conversation: conversation)
      case .hashTag(let tag, let accountId):
        TimelineView(
          timeline: .constant(.hashtag(tag: tag, accountId: accountId)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .list(let list):
        TimelineView(
          timeline: .constant(.list(list: list)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .linkTimeline(let url, let title):
        TimelineView(
          timeline: .constant(.link(url: url, title: title)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .quotes(let id):
        TimelineView(
          timeline: .constant(.quotes(statusId: id)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .following(let id):
        AccountsListView(mode: .following(accountId: id))
      case .followers(let id):
        AccountsListView(mode: .followers(accountId: id))
      case .favoritedBy(let id):
        AccountsListView(mode: .favoritedBy(statusId: id))
      case .rebloggedBy(let id):
        AccountsListView(mode: .rebloggedBy(statusId: id))
      case .accountsList(let accounts):
        AccountsListView(mode: .accountsList(accounts: accounts))
      case .trendingTimeline:
        TimelineView(
          timeline: .constant(.trending),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .trendingLinks(let cards):
        TrendingLinksListView(cards: cards)
      case .tagsList(let tags):
        TagsListView(tags: tags)
      case .notificationsRequests:
        NotificationsRequestsListView()
      case .notificationForAccount(let accountId):
        NotificationsListView(
          lockedType: nil,
          lockedAccountId: accountId)
      case .blockedAccounts:
        AccountsListView(mode: .blocked)
      case .mutedAccounts:
        AccountsListView(mode: .muted)
      case .conversations:
        ConversationsListView()
      case .instanceInfo(let instance):
        InstanceInfoView(instance: instance)
      }
    }
  }

  func withSheetDestinations(sheetDestinations: Binding<SheetDestination?>) -> some View {
    sheet(item: sheetDestinations) { destination in
      switch destination {
      case .replyToStatusEditor(let status):
        StatusEditor.MainView(mode: .replyTo(status: status))
          .withEnvironments()
      case .newStatusEditor(let visibility):
        StatusEditor.MainView(mode: .new(text: nil, visibility: visibility))
          .withEnvironments()
      case .prefilledStatusEditor(let text, let visibility):
        StatusEditor.MainView(mode: .new(text: text, visibility: visibility))
          .withEnvironments()
      case .imageURL(let urls, let caption, let altTexts, let visibility):
        StatusEditor.MainView(
          mode: .imageURL(urls: urls, caption: caption, altTexts: altTexts, visibility: visibility)
        )
        .withEnvironments()
      case .editStatusEditor(let status):
        StatusEditor.MainView(mode: .edit(status: status))
          .withEnvironments()
      case .quoteStatusEditor(let status):
        StatusEditor.MainView(mode: .quote(status: status))
          .withEnvironments()
      case .quoteLinkStatusEditor(let link):
        StatusEditor.MainView(mode: .quoteLink(link: link))
          .withEnvironments()
      case .mentionStatusEditor(let account, let visibility):
        StatusEditor.MainView(mode: .mention(account: account, visibility: visibility))
          .withEnvironments()
      case .listCreate:
        ListCreateView()
          .withEnvironments()
      case .listEdit(let list):
        ListEditView(list: list)
          .withEnvironments()
      case .listAddAccount(let account):
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
      case .statusEditHistory(let status):
        StatusEditHistoryView(statusId: status)
          .withEnvironments()
      case .settings:
        SettingsTabs(isModal: true)
          .withEnvironments()
          .preferredColorScheme(Theme.shared.selectedScheme == .dark ? .dark : .light)
      case .accountPushNotficationsSettings:
        if let subscription = PushNotificationsService.shared.subscriptions.first(where: {
          $0.account.token == AppAccountsManager.shared.currentAccount.oauthToken
        }) {
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
      case .report(let status):
        ReportView(status: status)
          .withEnvironments()
      case .shareImage(let image, let status):
        ActivityView(image: image, status: status)
          .withEnvironments()
      case .editTagGroup(let tagGroup, let onSaved):
        EditTagGroupView(tagGroup: tagGroup, onSaved: onSaved)
          .withEnvironments()
      case .timelineContentFilter:
        TimelineContentFilterView()
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

    func activityViewController(
      _: UIActivityViewController,
      itemForActivityType _: UIActivity.ActivityType?
    ) -> Any? {
      nil
    }
  }

  func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityView>)
    -> UIActivityViewController
  {
    UIActivityViewController(
      activityItems: [image, LinkDelegate(image: image, status: status)],
      applicationActivities: nil)
  }

  func updateUIViewController(
    _: UIActivityViewController, context _: UIViewControllerRepresentableContext<ActivityView>
  ) {}
}

extension URL: @retroactive Identifiable {
  public var id: String {
    absoluteString
  }
}
