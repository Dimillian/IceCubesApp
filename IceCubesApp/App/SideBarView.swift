import Account
import AppAccount
import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct SideBarView<Content: View>: View {
  @Environment(\.openWindow) private var openWindow

  @Environment(AppAccountsManager.self) private var appAccounts
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(RouterPath.self) private var routerPath

  @Binding var selectedTab: Tab
  @Binding var popToRootTab: Tab
  var tabs: [Tab]
  @ViewBuilder var content: () -> Content

  private func badgeFor(tab: Tab) -> Int {
    if tab == .notifications, selectedTab != tab,
       let token = appAccounts.currentAccount.oauthToken
    {
      return watcher.unreadNotificationsCount + (userPreferences.notificationsCount[token] ?? 0)
    }
    return 0
  }

  private func makeIconForTab(tab: Tab) -> some View {
    ZStack(alignment: .topTrailing) {
      SideBarIcon(systemIconName: tab.iconName,
                  isSelected: tab == selectedTab)
      let badge = badgeFor(tab: tab)
      if badge > 0 {
        makeBadgeView(count: badge)
      }
    }
    .contentShape(Rectangle())
    .frame(width: .sidebarWidth, height: 50)
  }

  private func makeBadgeView(count: Int) -> some View {
    ZStack {
      Circle()
        .fill(.red)
      Text(count > 99 ? "99+" : String(count))
        .foregroundColor(.white)
        .font(.caption2)
    }
    .frame(width: 24, height: 24)
    .offset(x: 14, y: -14)
  }

  private var postButton: some View {
    Button {
      #if targetEnvironment(macCatalyst)
        openWindow(value: WindowDestinationEditor.newStatusEditor(visibility: userPreferences.postVisibility))
      #else
        routerPath.presentedSheet = .newStatusEditor(visibility: userPreferences.postVisibility)
      #endif
    } label: {
      Image(systemName: "square.and.pencil")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 20, height: 30)
    }
    .buttonStyle(.borderedProminent)
  }

  private func makeAccountButton(account: AppAccount, showBadge: Bool) -> some View {
    Button {
      if account.id == appAccounts.currentAccount.id {
        selectedTab = .profile
        SoundEffectManager.shared.playSound(.tabSelection)
      } else {
        var transation = Transaction()
        transation.disablesAnimations = true
        withTransaction(transation) {
          appAccounts.currentAccount = account
        }
      }
    } label: {
      ZStack(alignment: .topTrailing) {
        AppAccountView(viewModel: .init(appAccount: account, isCompact: true))
        if showBadge,
           let token = account.oauthToken,
           let notificationsCount = userPreferences.notificationsCount[token],
           notificationsCount > 0
        {
          makeBadgeView(count: notificationsCount)
        }
      }
    }
    .frame(width: .sidebarWidth, height: 50)
    .padding(.vertical, 8)
    .background(selectedTab == .profile && account.id == appAccounts.currentAccount.id ?
      theme.secondaryBackgroundColor : .clear)
  }

  private var tabsView: some View {
    ForEach(tabs) { tab in
      Button {
        // ensure keyboard is always dismissed when selecting a tab
        hideKeyboard()

        if tab == selectedTab {
          popToRootTab = .other
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            popToRootTab = tab
          }
        }
        selectedTab = tab
        SoundEffectManager.shared.playSound(.tabSelection)
        if tab == .notifications {
          if let token = appAccounts.currentAccount.oauthToken {
            userPreferences.notificationsCount[token] = 0
          }
          watcher.unreadNotificationsCount = 0
        }
      } label: {
        makeIconForTab(tab: tab)
      }
      .background(tab == selectedTab ? theme.secondaryBackgroundColor : .clear)
    }
  }

  var body: some View {
    @Bindable var routerPath = routerPath
    HStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .center) {
          if appAccounts.availableAccounts.isEmpty {
            tabsView
          } else {
            ForEach(appAccounts.availableAccounts) { account in
              makeAccountButton(account: account,
                                showBadge: account.id != appAccounts.currentAccount.id)
              if account.id == appAccounts.currentAccount.id {
                tabsView
              }
            }
          }
          postButton
            .padding(.top, 12)
          Spacer()
        }
      }
      .frame(width: .sidebarWidth)
      .scrollContentBackground(.hidden)
      .background(.thinMaterial)
      Divider()
        .edgesIgnoringSafeArea(.top)
      content()
    }
    .background(.thinMaterial)
    .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
  }
}

private struct SideBarIcon: View {
  @Environment(Theme.self) private var theme

  let systemIconName: String
  let isSelected: Bool

  @State private var isHovered: Bool = false

  var body: some View {
    Image(systemName: systemIconName)
      .font(.title2)
      .fontWeight(.medium)
      .foregroundColor(isSelected ? theme.tintColor : theme.labelColor)
      .scaleEffect(isHovered ? 0.8 : 1.0)
      .onHover { isHovered in
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
          self.isHovered = isHovered
        }
      }
  }
}

extension View {
  @MainActor func hideKeyboard() {
    let resign = #selector(UIResponder.resignFirstResponder)
    UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
  }
}
