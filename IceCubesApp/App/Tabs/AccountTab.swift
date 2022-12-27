import SwiftUI
import Env
import Network
import Account
import Models
import Shimmer

struct AccountTab: View {
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
      } else {
        AccountDetailView(account: .placeholder())
          .redacted(reason: .placeholder)
          .shimmering()
      }
    }
    .environmentObject(routeurPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .account {
        routeurPath.path = []
      }
    }
    .onAppear {
      routeurPath.client = client
    }
  }
}
