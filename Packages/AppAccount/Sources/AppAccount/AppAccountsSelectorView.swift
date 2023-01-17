import SwiftUI
import Env
import DesignSystem

public struct AppAccountsSelectorView: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var appAccounts: AppAccountsManager
  
  @ObservedObject var routerPath: RouterPath
  
  @State private var accountsViewModel: [AppAccountViewModel] = []
  
  private let accountCreationEnabled: Bool
  private let avatarSize: AvatarView.Size
  
  public init(routerPath: RouterPath,
              accountCreationEnabled: Bool = true,
              avatarSize: AvatarView.Size = .badge) {
    self.routerPath = routerPath
    self.accountCreationEnabled = accountCreationEnabled
    self.avatarSize = avatarSize
  }
  
  public var body: some View {
    Group {
      if UIDevice.current.userInterfaceIdiom == .pad {
        labelView
          .contextMenu {
            menuView
          }
      } else {
        Menu {
          menuView
        } label: {
          labelView
        }
      }
    }
    .onAppear {
      refreshAccounts()
    }
    .onChange(of: currentAccount.account?.id) { _ in
      refreshAccounts()
    }
  }
  
  @ViewBuilder
  private var labelView: some View {
    if let avatar = currentAccount.account?.avatar {
      AvatarView(url: avatar, size: avatarSize)
    } else {
      EmptyView()
    }
  }
  
  @ViewBuilder
  private var menuView: some View {
    ForEach(accountsViewModel, id: \.appAccount.id) { viewModel in
      Section(viewModel.acct) {
        Button {
          if let account = currentAccount.account,
              viewModel.account?.id == account.id {
            routerPath.navigate(to: .accountDetailWithAccount(account: account))
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
    if accountCreationEnabled {
      Divider()
      Button {
        routerPath.presentedSheet = .addAccount
      } label: {
        Label("Add Account", systemImage: "person.badge.plus")
      }
    }
  }
  
  private func refreshAccounts() {
    if accountsViewModel.isEmpty || appAccounts.availableAccounts.count != accountsViewModel.count {
      accountsViewModel = []
      for account in appAccounts.availableAccounts {
        let viewModel: AppAccountViewModel = .init(appAccount: account)
        Task {
          await viewModel.fetchAccount()
          if !accountsViewModel.contains(where: { $0.acct == viewModel.acct }) {
            accountsViewModel.append(viewModel)
          }
        }
      }
    }
  }
  
}
