import SwiftUI
import DesignSystem

struct AppAccountView: View {
  @EnvironmentObject var appAccounts: AppAccountsManager
  @StateObject var viewModel: AppAccountViewModel
  
  var body: some View {
    HStack {
      if let account = viewModel.account {
        ZStack(alignment: .topTrailing) {
          AvatarView(url: account.avatar)
          if viewModel.appAccount.id == appAccounts.currentAccount.id {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.white, .green)
              .offset(x: 5, y: -5)
          }
        }
      }
      VStack(alignment: .leading) {
        if let account = viewModel.account {
          account.displayNameWithEmojis
          Text("\(account.username)@\(viewModel.appAccount.server)")
            .font(.subheadline)
            .foregroundColor(.gray)
        }
      }
    }
    .onAppear {
      Task {
        await viewModel.fetchAccount()
      }
    }
  }
}
