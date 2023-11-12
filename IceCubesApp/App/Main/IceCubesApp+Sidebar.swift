import Env
import SwiftUI

extension IceCubesApp {
  var sidebarView: some View {
    SideBarView(selectedTab: $selectedTab,
                popToRootTab: $popToRootTab,
                tabs: availableTabs)
    {
      HStack(spacing: 0) {
        ZStack {
          if selectedTab == .profile {
            ProfileTab(popToRootTab: $popToRootTab)
          }
          ForEach(availableTabs) { tab in
            if tab == selectedTab || sideBarLoadedTabs.contains(tab) {
              tab
                .makeContentView(popToRootTab: $popToRootTab)
                .opacity(tab == selectedTab ? 1 : 0)
                .transition(.opacity)
                .id("\(tab)\(appAccountsManager.currentAccount.id)")
                .onAppear {
                  sideBarLoadedTabs.insert(tab)
                }
            } else {
              EmptyView()
            }
          }
        }
        if appAccountsManager.currentClient.isAuth,
           userPreferences.showiPadSecondaryColumn
        {
          Divider().edgesIgnoringSafeArea(.all)
          notificationsSecondaryColumn
        }
      }
    }.onChange(of: $appAccountsManager.currentAccount.id) {
      sideBarLoadedTabs.removeAll()
    }
    .environment(sidebarRouterPath)
  }

  var notificationsSecondaryColumn: some View {
    NotificationsTab(popToRootTab: $popToRootTab, lockedType: nil)
      .environment(\.isSecondaryColumn, true)
      .frame(maxWidth: .secondaryColumnWidth)
      .id(appAccountsManager.currentAccount.id)
  }
}
