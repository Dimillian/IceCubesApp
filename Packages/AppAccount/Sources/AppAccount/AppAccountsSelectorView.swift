import DesignSystem
import Env
import SwiftUI

public struct AppAccountsSelectorView: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var appAccounts: AppAccountsManager

  @ObservedObject var routerPath: RouterPath

  @State private var accountsViewModel: [AppAccountViewModel] = []

  let feedbackGenerator = UIImpactFeedbackGenerator()

  private let accountCreationEnabled: Bool
  private let avatarSize: AvatarView.Size

  public init(routerPath: RouterPath,
              accountCreationEnabled: Bool = true,
              avatarSize: AvatarView.Size = .badge)
  {
    self.routerPath = routerPath
    self.accountCreationEnabled = accountCreationEnabled
    self.avatarSize = avatarSize

    feedbackGenerator.prepare()
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
    .onTapGesture {
      feedbackGenerator.impactOccurred(intensity: 0.3)
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
    Group {
      if let avatar = currentAccount.account?.avatar {
        AvatarView(url: avatar, size: avatarSize)
      } else {
        ProgressView()
      }
    }.overlay(alignment: .topTrailing) {
      if !currentAccount.followRequests.isEmpty {
        Circle()
          .fill(Color.red)
          .frame(width: 9, height: 9)
      }
    }
  }

  @ViewBuilder
  private var menuView: some View {
    ForEach(accountsViewModel, id: \.appAccount.id) { viewModel in
      Section(viewModel.acct) {
        Button {
          if let account = currentAccount.account,
             viewModel.account?.id == account.id
          {
            routerPath.navigate(to: .accountDetailWithAccount(account: account))
          } else {
            appAccounts.currentAccount = viewModel.appAccount
          }

          feedbackGenerator.impactOccurred(intensity: 0.7)
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
        Label("app-account.button.add", systemImage: "person.badge.plus")
      }
    }

    if UIDevice.current.userInterfaceIdiom == .phone {
      Divider()
      Button {
        routerPath.presentedSheet = .settings
      } label: {
        Label("tab.settings", systemImage: "gear")
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
