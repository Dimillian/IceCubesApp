import SwiftUI
import Env
import DesignSystem

struct AppAccountsSelectorView: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var appAccounts: AppAccountsManager
  
  @ObservedObject var routeurPath: RouterPath
  
  @State private var accountsViewModel: [AppAccountViewModel] = []
  
  var body: some View {
    Button {
      if let account = currentAccount.account {
        routeurPath.navigate(to: .accountDetailWithAccount(account: account))
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
    .contextMenu {
      ForEach(accountsViewModel, id: \.appAccount.id) { viewModel in
        Button {
          appAccounts.currentAccount = viewModel.appAccount
        } label: {
          HStack {
            if viewModel.account?.id == currentAccount.account?.id {
              Image(systemName: "checkmark.circle.fill")
            }
            Text("\(viewModel.account?.displayName ?? "")")
          }
        }
      }
      Button {
        routeurPath.presentedSheet = .addAccount
      } label: {
        Label("Add Account", systemImage: "person.badge.plus")
      }
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
        accountsViewModel.append(viewModel)
        Task {
          await viewModel.fetchAccount()
        }
      }
    }
  }
}
