import AppAccount
import DesignSystem
import Env
import Explore
import Models
import Network
import Shimmer
import SwiftUI

struct ExploreTab: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var client: Client
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      ExploreView()
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
        .toolbar {
          statusEditorToolbarItem(routerPath: routerPath,
                                  visibility: preferences.postVisibility)
          if UIDevice.current.userInterfaceIdiom != .pad {
            ToolbarItem(placement: .navigationBarLeading) {
              AppAccountsSelectorView(routerPath: routerPath)
            }
          }
        }
    }
    .withSafariRouter()
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
