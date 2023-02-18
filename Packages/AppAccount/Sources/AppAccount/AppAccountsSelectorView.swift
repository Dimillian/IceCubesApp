import DesignSystem
import Env
import SwiftUI

public struct AppAccountsSelectorView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var appAccounts: AppAccountsManager

  @ObservedObject var routerPath: RouterPath

  @State private var accountsViewModel: [AppAccountViewModel] = []

  private let accountCreationEnabled: Bool
  private let avatarSize: AvatarView.Size

  public init(routerPath: RouterPath,
              accountCreationEnabled: Bool = true,
              avatarSize: AvatarView.Size = .badge)
  {
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
    .onTapGesture {
      HapticManager.shared.fireHaptic(of: .buttonPress)
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
      if let avatar = currentAccount.account?.avatar, !currentAccount.isLoadingAccount {
        AvatarView(url: avatar, size: avatarSize)
      } else {
        AvatarView(url: nil, size: avatarSize)
          .redacted(reason: .placeholder)
      }
    }.overlay(alignment: .topTrailing) {
      if !currentAccount.followRequests.isEmpty {
        Circle()
          .fill(Color.red)
          .frame(width: 9, height: 9)
      }
    }
    .accessibilityLabel("accessibility.app-account.selector.accounts")
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
            var transation = Transaction()
            transation.disablesAnimations = true
            withTransaction(transation) {
              appAccounts.currentAccount = viewModel.appAccount
            }
          }

          HapticManager.shared.fireHaptic(of: .buttonPress)
        } label: {
          HStack {
            if let image = viewModel.roundedAvatar {
              Image(uiImage: image)
            }
            if let token = viewModel.appAccount.oauthToken,
               preferences.getNotificationsCount(for: token) > 0 {
              Text("\(viewModel.account?.displayName ?? "") (\(preferences.getNotificationsCount(for: token)))")
            } else {
              Text("\(viewModel.account?.displayName ?? "")")
            }
          }
        }
      }
    }
    if accountCreationEnabled {
      Divider()
      Button {
        HapticManager.shared.fireHaptic(of: .buttonPress)
        routerPath.presentedSheet = .addAccount
      } label: {
        Label("app-account.button.add", systemImage: "person.badge.plus")
      }
    }

    if UIDevice.current.userInterfaceIdiom == .phone && accountCreationEnabled {
      Divider()
      Button {
        HapticManager.shared.fireHaptic(of: .buttonPress)
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
