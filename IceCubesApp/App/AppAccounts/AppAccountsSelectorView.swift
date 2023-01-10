import SwiftUI
import Env
import DesignSystem

struct AppAccountsSelectorView: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var appAccounts: AppAccountsManager
  
  @ObservedObject var routeurPath: RouterPath
  
  @State private var accountsViewModel: [AppAccountViewModel] = []
  
  var body: some View {
    Menu {
      ForEach(accountsViewModel, id: \.appAccount.id) { viewModel in
        Section(viewModel.acct) {
          Button {
            if let account = currentAccount.account,
                viewModel.account?.id == account.id {
              routeurPath.navigate(to: .accountDetailWithAccount(account: account))
            } else {
              appAccounts.currentAccount = viewModel.appAccount
            }
          } label: {
            HStack {
              if viewModel.account?.id == currentAccount.account?.id {
                Image(systemName: "checkmark.circle.fill")
              }
              Text("\(viewModel.account?.displayName ?? "")")
            }
          }
        }
      }
      Divider()
      Button {
        routeurPath.presentedSheet = .addAccount
      } label: {
        Label("Add Account", systemImage: "person.badge.plus")
      }
    } label: {
      if let avatar = currentAccount.account?.avatar {
        AvatarView(url: avatar, size: .badge)
      } else {
        EmptyView()
      }
    }
    .onAppear {
      refreshAccounts()
    }
    .onChange(of: currentAccount.account?.id) { _ in
      refreshAccounts()
    }
  }
  
  private func refreshAccounts() {
    if accountsViewModel.isEmpty || appAccounts.availableAccounts.count != accountsViewModel.count {
      accountsViewModel = []
      for account in appAccounts.availableAccounts {
        let viewModel: AppAccountViewModel = .init(appAccount: account)
        Task {
          await viewModel.fetchAccount()
          accountsViewModel.append(viewModel)
        }
      }
    }
  }
}
