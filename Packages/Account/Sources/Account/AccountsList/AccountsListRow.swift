import Combine
import DesignSystem
import EmojiText
import Env
import Models
import Network
import SwiftUI
import Observation

@MainActor
@Observable public class AccountsListRowViewModel {
  var client: Client?

  var account: Account
  var relationShip: Relationship?

  public init(account: Account, relationShip: Relationship? = nil) {
    self.account = account
    self.relationShip = relationShip
  }
}

public struct AccountsListRow: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var routerPath: RouterPath
  @Environment(Client.self) private var client

  @State var viewModel: AccountsListRowViewModel

  @State private var isEditingRelationshipNote: Bool = false

  let isFollowRequest: Bool
  let requestUpdated: (() -> Void)?

  public init(viewModel: AccountsListRowViewModel, isFollowRequest: Bool = false, requestUpdated: (() -> Void)? = nil) {
    self.viewModel = viewModel
    self.isFollowRequest = isFollowRequest
    self.requestUpdated = requestUpdated
  }

  public var body: some View {
    HStack(alignment: .top) {
      AvatarView(url: viewModel.account.avatar, size: .status)
      VStack(alignment: .leading, spacing: 2) {
        EmojiTextApp(.init(stringValue: viewModel.account.safeDisplayName), emojis: viewModel.account.emojis)
          .font(.scaledSubheadline)
          .emojiSize(Font.scaledSubheadlineFont.emojiSize)
          .emojiBaselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
          .fontWeight(.semibold)
        Text("@\(viewModel.account.acct)")
          .font(.scaledFootnote)
          .foregroundColor(.gray)

        // First parameter is the number for the plural
        // Second parameter is the formatted string to show
        Text("account.label.followers \(viewModel.account.followersCount ?? 0) \(viewModel.account.followersCount ?? 0, format: .number.notation(.compactName))")
          .font(.scaledFootnote)

        if let field = viewModel.account.fields.filter({ $0.verifiedAt != nil }).first {
          HStack(spacing: 2) {
            Image(systemName: "checkmark.seal")
              .font(.scaledFootnote)
              .foregroundColor(.green)

            EmojiTextApp(field.value, emojis: viewModel.account.emojis)
              .font(.scaledFootnote)
              .emojiSize(Font.scaledFootnoteFont.emojiSize)
              .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
              .environment(\.openURL, OpenURLAction { url in
                routerPath.handle(url: url)
              })
          }
        }

        EmojiTextApp(viewModel.account.note, emojis: viewModel.account.emojis, lineLimit: 2)
          .font(.scaledCaption)
          .emojiSize(Font.scaledFootnoteFont.emojiSize)
          .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
          .environment(\.openURL, OpenURLAction { url in
            routerPath.handle(url: url)
          })

        if isFollowRequest {
          FollowRequestButtons(account: viewModel.account,
                               requestUpdated: requestUpdated)
        }
      }
      Spacer()
      if currentAccount.account?.id != viewModel.account.id,
         let relationShip = viewModel.relationShip
      {
        VStack(alignment: .center) {
          FollowButton(viewModel: .init(accountId: viewModel.account.id,
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
    .contextMenu {
      AccountDetailContextMenu(viewModel: .init(account: viewModel.account))
    } preview: {
      List {
        AccountDetailHeaderView(viewModel: .init(account: viewModel.account),
                                account: viewModel.account,
                                scrollViewProxy: nil)
          .applyAccountDetailsRowStyle(theme: theme)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      .environmentObject(theme)
      .environmentObject(currentAccount)
      .environment(client)
    }
  }
}
