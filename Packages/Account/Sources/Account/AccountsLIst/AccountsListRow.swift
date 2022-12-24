import SwiftUI
import Models
import Network
import DesignSystem
import Env

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
        viewModel.account.displayNameWithEmojis
          .font(.subheadline)
          .fontWeight(.semibold)
        Text("@\(viewModel.account.acct)")
          .font(.footnote)
          .foregroundColor(.gray)
        Text(viewModel.account.note.asSafeAttributedString)
          .font(.footnote)
          .lineLimit(3)
          .environment(\.openURL, OpenURLAction { url in
            routeurPath.handle(url: url)
          })
      }
      Spacer()
      FollowButton(viewModel: .init(accountId: viewModel.account.id,
                                    relationship: viewModel.relationShip))
    }
    .onAppear {
      viewModel.client = client
    }
    .onTapGesture {
      routeurPath.navigate(to: .accountDetailWithAccount(account: viewModel.account))
    }
  }
}
