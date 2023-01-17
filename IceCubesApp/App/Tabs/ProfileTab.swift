import Account
import AppAccount
import Conversations
import Env
import Models
import Network
import Shimmer
import SwiftUI

struct ProfileTab: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      if let account = currentAccount.account {
        AccountDetailView(account: account)
          .withAppRouteur()
          .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
          .toolbar {
            if UIDevice.current.userInterfaceIdiom != .pad {
              ToolbarItem(placement: .navigationBarLeading) {
                AppAccountsSelectorView(routeurPath: routeurPath)
              }
            }
          }
          .id(currentAccount.account?.id)
      } else {
        AccountDetailView(account: .placeholder())
          .redacted(reason: .placeholder)
          .shimmering()
      }
    }
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .messages {
        routeurPath.path = []
      }
    }
    .onChange(of: currentAccount.account?.id) { _ in
      routeurPath.path = []
    }
    .onAppear {
      routeurPath.client = client
    }
    .withSafariRouteur()
    .environmentObject(routeurPath)
  }
}
