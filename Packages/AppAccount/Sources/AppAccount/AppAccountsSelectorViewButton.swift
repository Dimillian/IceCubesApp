import DesignSystem
import Env
import SwiftUI

@MainActor
public struct AppAccountsSelectorViewButton: View {
  @Environment(UserPreferences.self) private var preferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(AppAccountsManager.self) private var appAccounts
  @Environment(Theme.self) private var theme

  var routerPath: RouterPath

  @State private var accountsViewModel: [AppAccountViewModel] = []
  @State private var isPresented: Bool = false

  private let accountCreationEnabled: Bool
  private let avatarConfig: AvatarView.FrameConfig

  private var showNotificationBadge: Bool {
    accountsViewModel
      .filter { $0.account?.id != currentAccount.account?.id }
      .compactMap(\.appAccount.oauthToken)
      .map { preferences.notificationsCount[$0] ?? 0 }
      .reduce(0, +) > 0
  }

  private var preferredHeight: CGFloat {
    var baseHeight: CGFloat = 310
    baseHeight += CGFloat(60 * accountsViewModel.count)
    return baseHeight
  }

  public init(routerPath: RouterPath,
              accountCreationEnabled: Bool = true,
              avatarConfig: AvatarView.FrameConfig = .badge)
  {
    self.routerPath = routerPath
    self.accountCreationEnabled = accountCreationEnabled
    self.avatarConfig = avatarConfig
  }

  public var body: some View {
    Button {
      isPresented.toggle()
      HapticManager.shared.fireHaptic(.buttonPress)
    } label: {
      labelView
        .contentShape(Rectangle())
    }
    .sheet(isPresented: $isPresented, content: {
        AppAccountsSelectorView(routerPath: routerPath, accountCreationEnabled: accountCreationEnabled, accountsViewModel: $accountsViewModel, isPresented: $isPresented)
        .presentationDetents([.height(preferredHeight), .large])
        .presentationBackground(.thinMaterial)
        .presentationCornerRadius(16)
        .onAppear {
          refreshAccounts()
        }
    })
    .onChange(of: currentAccount.account?.id) {
      refreshAccounts()
    }
    .onAppear {
      refreshAccounts()
    }
    .accessibilityRepresentation {
      Menu("accessibility.app-account.selector.accounts") {}
        .accessibilityHint("accessibility.app-account.selector.accounts.hint")
        .accessibilityRemoveTraits(.isButton)
    }
  }

  @ViewBuilder
  private var labelView: some View {
    Group {
      if let account = currentAccount.account, !currentAccount.isLoadingAccount {
        AvatarView(account.avatar, config: avatarConfig)
      } else {
        AvatarView(config: avatarConfig)
          .redacted(reason: .placeholder)
          .allowsHitTesting(false)
      }
    }.overlay(alignment: .topTrailing) {
      if !currentAccount.followRequests.isEmpty || showNotificationBadge, accountCreationEnabled {
        Circle()
          .fill(Color.red)
          .frame(width: 9, height: 9)
      }
    }
  }

  private func refreshAccounts() {
    accountsViewModel = []
    for account in appAccounts.availableAccounts {
      let viewModel: AppAccountViewModel = .init(appAccount: account, isInNavigation: false, showBadge: true)
      accountsViewModel.append(viewModel)
    }
  }
}
