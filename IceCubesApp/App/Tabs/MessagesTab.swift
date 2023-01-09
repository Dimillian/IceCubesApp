import SwiftUI
import Env
import Network
import Account
import Models
import Shimmer
import Conversations
import Env

struct MessagesTab: View {
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: Tab
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      ConversationsListView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            AppAccountsSelectorView(routeurPath: routeurPath)
          }
        }
        .id(currentAccount.account?.id)
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
