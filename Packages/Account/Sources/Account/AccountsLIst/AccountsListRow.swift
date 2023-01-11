import SwiftUI
import Models
import Network
import DesignSystem
import Env
import EmojiText

@MainActor
public class AccountsListRowViewModel: ObservableObject {
  var client: Client?
  
  @Published var account: Account
  @Published var relationShip: Relationshionship
  
  public init(account: Account, relationShip: Relationshionship) {
    self.account = account
    self.relationShip = relationShip
  }
}

public struct AccountsListRow: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var routeurPath: RouterPath
  @EnvironmentObject private var client: Client
  
  @StateObject var viewModel: AccountsListRowViewModel
  
  public init(viewModel: AccountsListRowViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    HStack(alignment: .top) {
      AvatarView(url: viewModel.account.avatar, size: .status)
      VStack(alignment: .leading, spacing: 2) {
        EmojiText(viewModel.account.safeDisplayName, emojis: viewModel.account.emojis)
          .font(.subheadline)
          .fontWeight(.semibold)
        Text("@\(viewModel.account.acct)")
          .font(.footnote)
          .foregroundColor(.gray)
        EmojiText(viewModel.account.note, emojis: viewModel.account.emojis)
          .font(.footnote)
          .lineLimit(3)
          .environment(\.openURL, OpenURLAction { url in
            routeurPath.handle(url: url)
          })
      }
      Spacer()
      if currentAccount.account?.id != viewModel.account.id {
        FollowButton(viewModel: .init(accountId: viewModel.account.id,
                                      relationship: viewModel.relationShip))
      }
    }
    .onAppear {
      viewModel.client = client
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routeurPath.navigate(to: .accountDetailWithAccount(account: viewModel.account))
    }
  }
}
