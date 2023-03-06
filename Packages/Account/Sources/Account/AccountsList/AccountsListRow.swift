import Combine
import DesignSystem
import EmojiText
import Env
import Models
import Network
import SwiftUI

@MainActor
public class AccountsListRowViewModel: ObservableObject {
  var client: Client?

  @Published var account: Account
  @Published var relationShip: Relationship?

  public init(account: Account, relationShip: Relationship? = nil) {
    self.account = account
    self.relationShip = relationShip
  }
}

public struct AccountsListRow: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var client: Client

  @StateObject var viewModel: AccountsListRowViewModel
  
  @State private var isEditingRelationshipNote: Bool = false
  
  let isFollowRequest: Bool
  let requestUpdated: (() -> Void)?

  public init(viewModel: AccountsListRowViewModel, isFollowRequest: Bool = false, requestUpdated: (() -> Void)? = nil) {
    _viewModel = StateObject(wrappedValue: viewModel)
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
        EmojiTextApp(viewModel.account.note, emojis: viewModel.account.emojis)
          .font(.scaledFootnote)
          .emojiSize(Font.scaledFootnoteFont.emojiSize)
          .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
          .lineLimit(3)
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
      .environmentObject(client)
    }

  }
}
