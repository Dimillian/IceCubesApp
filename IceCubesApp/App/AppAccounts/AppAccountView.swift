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
              .foregroundColor(.green)
              .offset(x: 5, y: -5)
          }
        }
      }
      VStack(alignment: .leading) {
        Text(viewModel.appAccount.server)
          .font(.headline)
        if let account = viewModel.account {
          Text(account.displayName)
          Text(account.username)
            .font(.footnote)
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
