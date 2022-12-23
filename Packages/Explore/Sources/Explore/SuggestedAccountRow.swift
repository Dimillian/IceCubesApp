import SwiftUI
import Models
import Network
import DesignSystem
import Env
import Account

@MainActor
class SuggestedAccountViewModel: ObservableObject {
  var client: Client?
  
  @Published var account: Account
  @Published var relationShip: Relationshionship
  
  init(account: Account, relationShip: Relationshionship) {
    self.account = account
    self.relationShip = relationShip
  }
}

struct SuggestedAccountRow: View {
  @EnvironmentObject private var routeurPath: RouterPath
  @EnvironmentObject private var client: Client
  
  @StateObject var viewModel: SuggestedAccountViewModel
  
  var body: some View {
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
          .font(.callout)
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
