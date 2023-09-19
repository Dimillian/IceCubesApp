import DesignSystem
import Env
import SwiftUI

public struct AppAccountsSelectorView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(AppAccountsManager.self) private var appAccounts
  @Environment(Theme.self) private var theme

  var routerPath: RouterPath

  @State private var accountsViewModel: [AppAccountViewModel] = []
  @State private var isPresented: Bool = false

  private let accountCreationEnabled: Bool
  private let avatarSize: AvatarView.Size

  private var showNotificationBadge: Bool {
    accountsViewModel
      .filter { $0.account?.id != currentAccount.account?.id }
      .compactMap(\.appAccount.oauthToken)
      .map { preferences.notificationsCount[$0] ?? 0 }
      .reduce(0, +) > 0
  }

  private var preferredHeight: CGFloat {
    var baseHeight: CGFloat = 220
    baseHeight += CGFloat(60 * accountsViewModel.count)
    return baseHeight
  }

  public init(routerPath: RouterPath,
              accountCreationEnabled: Bool = true,
              avatarSize: AvatarView.Size = .badge)
  {
    self.routerPath = routerPath
    self.accountCreationEnabled = accountCreationEnabled
    self.avatarSize = avatarSize
  }

  public var body: some View {
    Button {
      isPresented.toggle()
      HapticManager.shared.fireHaptic(of: .buttonPress)
    } label: {
      labelView
    }
    .sheet(isPresented: $isPresented, content: {
      if #available(iOS 16.4, *) {
        accountsView.presentationDetents([.height(preferredHeight), .large])
          .presentationBackground(.thinMaterial)
          .presentationCornerRadius(16)
          .onAppear {
            refreshAccounts()
          }
      } else {
        accountsView.presentationDetents([.height(preferredHeight), .large])
          .onAppear {
            refreshAccounts()
          }
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
      if let avatar = currentAccount.account?.avatar, !currentAccount.isLoadingAccount {
        AvatarView(url: avatar, size: avatarSize)
      } else {
        AvatarView(url: nil, size: avatarSize)
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

  private var accountBackgroundColor: Color {
    if #available(iOS 16.4, *) {
      return Color.clear
    } else {
      return theme.secondaryBackgroundColor
    }
  }

  private var accountsView: some View {
    NavigationStack {
      List {
        Section {
          ForEach(accountsViewModel.sorted { $0.acct < $1.acct }, id: \.appAccount.id) { viewModel in
            AppAccountView(viewModel: viewModel)
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)

        if accountCreationEnabled {
          Section {
            Button {
              isPresented = false
              HapticManager.shared.fireHaptic(of: .buttonPress)
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                routerPath.presentedSheet = .addAccount
              }
            } label: {
              Label("app-account.button.add", systemImage: "person.badge.plus")
            }
            settingsButton
          }
          .listRowBackground(theme.primaryBackgroundColor)
        }
      }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(accountBackgroundColor)
      .navigationTitle("settings.section.accounts")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            isPresented.toggle()
          } label: {
            Text("action.done").bold()
          }
        }
      }
    }
  }

  private var settingsButton: some View {
    Button {
      isPresented = false
      HapticManager.shared.fireHaptic(of: .buttonPress)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        routerPath.presentedSheet = .settings
      }
    } label: {
      Label("tab.settings", systemImage: "gear")
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
