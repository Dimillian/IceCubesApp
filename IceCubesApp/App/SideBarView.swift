import SwiftUI
import Env
import Account
import DesignSystem

struct SideBarView<Content: View>: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var theme: Theme
  
  @Binding var selectedTab: Tab
  @Binding var popToRootTab: Tab
  var tabs: [Tab]
  @ViewBuilder var content: (Tab) -> Content
  
  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .center) {
        if let account = currentAccount.account {
          AvatarView(url: account.avatar)
            .frame(width: 70, height: 50)
            .background(selectedTab == .profile ? theme.secondaryBackgroundColor : .clear)
            .onTapGesture {
              selectedTab = .profile
            }
        }
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
          .frame(width: 70, height: 50)
          .background(tab == selectedTab ? theme.secondaryBackgroundColor : .clear)
        }
        Spacer()
      }
      .frame(width: 70)
      .background(.clear)
      Divider()
        .edgesIgnoringSafeArea(.top)
      content(selectedTab)
    }
    .background(.thinMaterial)
  }
}
