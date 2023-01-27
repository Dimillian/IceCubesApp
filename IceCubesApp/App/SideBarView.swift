import Account
import AppAccount
import DesignSystem
import Env
import Models
import SwiftUI

struct SideBarView<Content: View>: View {
  @EnvironmentObject private var appAccounts: AppAccountsManager
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var userPreferences: UserPreferences

  @Binding var selectedTab: Tab
  @Binding var popToRootTab: Tab
  var tabs: [Tab]
  @ObservedObject var routerPath = RouterPath()
  @ViewBuilder var content: () -> Content

  private func badgeFor(tab: Tab) -> Int {
    if tab == .notifications && selectedTab != tab {
      return watcher.unreadNotificationsCount + userPreferences.pushNotificationsCount
    }
    return 0
  }

  private var profileView: some View {
    Button {
      selectedTab = .profile
    } label: {
      AppAccountsSelectorView(routerPath: RouterPath(),
                              accountCreationEnabled: false,
                              avatarSize: .status)
    }
    .frame(width: .sidebarWidth, height: 60)
    .background(selectedTab == .profile ? theme.secondaryBackgroundColor : .clear)
  }

  private func makeIconForTab(tab: Tab) -> some View {
    ZStack(alignment: .topTrailing) {
      SideBarIcon(systemIconName: tab.iconName,
                  isSelected: tab == selectedTab)
      if let badge = badgeFor(tab: tab), badge > 0 {
        ZStack {
          Circle()
            .fill(.red)
          Text(String(badge))
            .foregroundColor(.white)
            .font(.caption2)
        }
        .frame(width: 20, height: 20)
        .offset(x: 10, y: -10)
      }
    }
    .contentShape(Rectangle())
    .frame(width: .sidebarWidth, height: 50)
  }

  private var postButton: some View {
    Button {
      routerPath.presentedSheet = .newStatusEditor(visibility: userPreferences.postVisibility)
    } label: {
      Image(systemName: "square.and.pencil")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 20, height: 30)
    }
    .buttonStyle(.borderedProminent)
    .keyboardShortcut("n", modifiers: .command)
  }

  private func makeAccountButton(account: AppAccount) -> some View {
    Button {
      if account.id == appAccounts.currentAccount.id {
        selectedTab = .profile
      } else {
        withAnimation {
          appAccounts.currentAccount = account
        }
      }
    } label: {
      AppAccountView(viewModel: .init(appAccount: account, isCompact: true))
    }
    .frame(width: .sidebarWidth, height: 50)
    .padding(.vertical, 8)
    .background(selectedTab == .profile && account.id == appAccounts.currentAccount.id ?
      theme.secondaryBackgroundColor : .clear)
  }

  private var tabsView: some View {
    ForEach(tabs) { tab in
      Button {
        if tab == selectedTab {
          popToRootTab = .other
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            popToRootTab = tab
          }
        }
        selectedTab = tab
        if tab == .notifications {
          watcher.unreadNotificationsCount = 0
          userPreferences.pushNotificationsCount = 0
        }
      } label: {
        makeIconForTab(tab: tab)
      }
      .background(tab == selectedTab ? theme.secondaryBackgroundColor : .clear)
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .center) {
          if appAccounts.availableAccounts.isEmpty {
            tabsView
          } else {
            ForEach(appAccounts.availableAccounts) { account in
              makeAccountButton(account: account)
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
  @EnvironmentObject private var theme: Theme

  let systemIconName: String
  let isSelected: Bool

  @State private var isHovered: Bool = false

  var body: some View {
    Image(systemName: systemIconName)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 24, height: 24)
      .foregroundColor(isSelected ? theme.tintColor : theme.labelColor)
      .scaleEffect(isHovered ? 0.8 : 1.0)
      .onHover { isHovered in
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
          self.isHovered = isHovered
        }
      }
  }
}
