import SwiftUI
import Env
import Models
import Shimmer
import Explore
import Env
import Network

struct ExploreTab: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var client: Client
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: Tab
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      ExploreView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          statusEditorToolbarItem(routeurPath: routeurPath,
                                  visibility: preferences.serverPreferences?.postVisibility ?? .pub)
          ToolbarItem(placement: .navigationBarLeading) {
            AppAccountsSelectorView(routeurPath: routeurPath)
          }
        }
    }
    .withSafariRouteur()
    .environmentObject(routeurPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .explore {
        routeurPath.path = []
      }
    }
    .onChange(of: currentAccount.account?.id) { _ in
      routeurPath.path = []
    }
    .onAppear {
      routeurPath.client = client
    }
  }
}
