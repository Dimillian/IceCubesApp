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
import Status
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
                     selectedTagGroup: .constant(nil),
                     scrollToTopSignal: .constant(0),
                     canFilterTimeline: false)
      case let .list(list):
        TimelineView(timeline: .constant(.list(list: list)),
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
                     selectedTagGroup: .constant(nil),
                     scrollToTopSignal: .constant(0),
                     canFilterTimeline: false)
      case let .trendingLinks(cards):
        CardsListView(cards: cards)
      case let .tagsList(tags):
        TagsListView(tags: tags)
      }
    }
  }

  func withSheetDestinations(sheetDestinations: Binding<SheetDestination?>) -> some View {
    sheet(item: sheetDestinations) { destination in
      Group {
        switch destination {
        case let .replyToStatusEditor(status):
          StatusEditorView(mode: .replyTo(status: status))
        case let .newStatusEditor(visibility):
          StatusEditorView(mode: .new(visibility: visibility))
        case let .editStatusEditor(status):
          StatusEditorView(mode: .edit(status: status))
        case let .quoteStatusEditor(status):
          StatusEditorView(mode: .quote(status: status))
        case let .mentionStatusEditor(account, visibility):
          StatusEditorView(mode: .mention(account: account, visibility: visibility))
        case .listCreate:
          ListCreateView()
        case let .listEdit(list):
          ListEditView(list: list)
        case let .listAddAccount(account):
          ListAddAccountView(account: account)
        case .addAccount:
          AddAccountView()
        case .addRemoteLocalTimeline:
          AddRemoteTimelineView()
        case .addTagGroup:
          EditTagGroupView()
        case let .statusEditHistory(status):
          StatusEditHistoryView(statusId: status)
        case .settings:
          SettingsTabs(popToRootTab: .constant(.settings), isModal: true)
            .preferredColorScheme(Theme.shared.selectedScheme == .dark ? .dark : .light)
        case .accountPushNotficationsSettings:
          if let subscription = PushNotificationsService.shared.subscriptions.first(where: { $0.account.token == AppAccountsManager.shared.currentAccount.oauthToken }) {
            PushNotificationsViewWrapper(subscription: subscription)
          } else {
            EmptyView()
          }
        case let .report(status):
          ReportView(status: status)
        case let .shareImage(image, status):
          ActivityView(image: image, status: status)
        case let .editTagGroup(tagGroup, onSaved):
          EditTagGroupView(tagGroup: tagGroup, onSaved: onSaved)
        }
      }
      .withEnvironments()
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
