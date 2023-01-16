import SwiftUI
import Env
import Account
import DesignSystem
import AppAccount

struct SideBarView<Content: View>: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var theme: Theme
  
  @Binding var selectedTab: Tab
  @Binding var popToRootTab: Tab
  var tabs: [Tab]
  @ViewBuilder var content: () -> Content
  
  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .center) {
        Button {
          selectedTab = .profile
        } label: {
          AppAccountsSelectorView(routeurPath: RouterPath(),
                                  accountCreationEnabled: false,
                                  avatarSize: .status)
        }
        .frame(width: 80, height: 60)
        .background(selectedTab == .profile ? theme.secondaryBackgroundColor : .clear)
        ForEach(tabs) { tab in
          Button {
            if tab == selectedTab {
              popToRootTab = .other
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                popToRootTab = tab
              }
            }
            selectedTab = tab
          } label: {
            Image(systemName: tab.iconName)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
              .foregroundColor(tab == selectedTab ? theme.tintColor : .gray)
          }
          .frame(width: 80, height: 50)
          .background(tab == selectedTab ? theme.secondaryBackgroundColor : .clear)
        }
        Spacer()
      }
      .frame(width: 80)
      .background(.clear)
      Divider()
        .edgesIgnoringSafeArea(.top)
      content()
    }
    .background(.thinMaterial)
  }
}
