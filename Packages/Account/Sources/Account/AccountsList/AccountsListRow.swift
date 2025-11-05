import Combine
import AppAccount
import DesignSystem
import EmojiText
import Env
import Models
import NetworkClient
import Observation
import SwiftUI

@MainActor
@Observable public class AccountsListRowViewModel {
  var client: MastodonClient?

  var account: Account
  var relationShip: Relationship?

  public init(account: Account, relationShip: Relationship? = nil) {
    self.account = account
    self.relationShip = relationShip
  }
}

@MainActor
public struct AccountsListRow: View {
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(RouterPath.self) private var routerPath
  @Environment(MastodonClient.self) private var client
  @Environment(QuickLook.self) private var quickLook
  @Environment(StreamWatcher.self) private var watcher
  @Environment(AppAccountsManager.self) private var appAccountsManager

  @State var viewModel: AccountsListRowViewModel

  @State private var isEditingRelationshipNote: Bool = false
  @State private var showBlockConfirmation: Bool = false
  @State private var showTranslateView: Bool = false

  let isFollowRequest: Bool
  let requestUpdated: (() -> Void)?

  public init(
    viewModel: AccountsListRowViewModel, isFollowRequest: Bool = false,
    requestUpdated: (() -> Void)? = nil
  ) {
    self.viewModel = viewModel
    self.isFollowRequest = isFollowRequest
    self.requestUpdated = requestUpdated
  }

  public var body: some View {
    HStack(alignment: .top) {
      AvatarView(viewModel.account.avatar)
      VStack(alignment: .leading, spacing: 2) {
        EmojiTextApp(
          .init(stringValue: viewModel.account.safeDisplayName), emojis: viewModel.account.emojis
        )
        .font(.scaledSubheadline)
        .emojiText.size(Font.scaledSubheadlineFont.emojiSize)
        .emojiText.baselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
        .fontWeight(.semibold)
        Text("@\(viewModel.account.acct)")
          .font(.scaledFootnote)
          .foregroundStyle(Color.secondary)

        // First parameter is the number for the plural
        // Second parameter is the formatted string to show
        Text(
          "account.label.followers \(viewModel.account.followersCount ?? 0) \(viewModel.account.followersCount ?? 0, format: .number.notation(.compactName))"
        )
        .font(.scaledFootnote)

        if let field = viewModel.account.fields.filter({ $0.verifiedAt != nil }).first {
          HStack(spacing: 2) {
            Image(systemName: "checkmark.seal")
              .font(.scaledFootnote)
              .foregroundColor(.green)

            EmojiTextApp(field.value, emojis: viewModel.account.emojis)
              .font(.scaledFootnote)
              .emojiText.size(Font.scaledFootnoteFont.emojiSize)
              .emojiText.baselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
              .environment(
                \.openURL,
                OpenURLAction { url in
                  routerPath.handle(url: url)
                })
          }
        }

        EmojiTextApp(viewModel.account.note, emojis: viewModel.account.emojis, lineLimit: 2)
          .font(.scaledCaption)
          .emojiText.size(Font.scaledFootnoteFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
          .environment(
            \.openURL,
            OpenURLAction { url in
              routerPath.handle(url: url)
            })

        if isFollowRequest {
          FollowRequestButtons(
            account: viewModel.account,
            requestUpdated: requestUpdated)
        }
      }
      Spacer()
      if currentAccount.account?.id != viewModel.account.id,
        let relationShip = viewModel.relationShip
      {
        VStack(alignment: .center) {
          FollowButton(
            viewModel: .init(
              client: client,
              accountId: viewModel.account.id,
              relationship: relationShip,
              shouldDisplayNotify: false,
              relationshipUpdated: { _ in }))
        }
      }
    }
    .onAppear {
      viewModel.client = client
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routerPath.navigate(to: .accountDetailWithAccount(account: viewModel.account))
    }
    #if canImport(_Translation_SwiftUI)
      .addTranslateView(isPresented: $showTranslateView, text: viewModel.account.note.asRawText)
    #endif
    .contextMenu {
      AccountDetailContextMenu(
        showBlockConfirmation: $showBlockConfirmation,
        showTranslateView: $showTranslateView,
        account: viewModel.account,
        relationship: .constant(viewModel.relationShip),
        isCurrentUser: false)
    } preview: {
      List {
        AccountDetailHeaderView(
          account: viewModel.account,
          relationship: viewModel.relationShip,
          fields: [],
          followButtonViewModel: .constant(nil),
          translation: .constant(nil),
          isLoadingTranslation: .constant(false),
          isCurrentUser: false,
          accountId: viewModel.account.id,
          scrollViewProxy: nil
        )
        .applyAccountDetailsRowStyle(theme: theme)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      .environment(theme)
      .environment(currentAccount)
      .environment(client)
      .environment(quickLook)
      .environment(routerPath)
      .environment(watcher)
      .environment(appAccountsManager)
    }
  }
}
