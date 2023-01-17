import SwiftUI
import Env
import Models
import Shimmer
import Explore
import Env
import Network
import AppAccount

struct ExploreTab: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var client: Client
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab
  
  var body: some View {
    NavigationStack(path: $routerPath.path) {
      ExploreView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          statusEditorToolbarItem(routerPath: routerPath,
                                  visibility: preferences.serverPreferences?.postVisibility ?? .pub)
          if UIDevice.current.userInterfaceIdiom != .pad {
            ToolbarItem(placement: .navigationBarLeading) {
              AppAccountsSelectorView(routerPath: routerPath)
            }
          }
        }
    }
    .withSafariRouteur()
    .environmentObject(routerPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .explore {
        routerPath.path = []
      }
    }
    .onChange(of: currentAccount.account?.id) { _ in
      routerPath.path = []
    }
    .onAppear {
      routerPath.client = client
    }
  }
}
