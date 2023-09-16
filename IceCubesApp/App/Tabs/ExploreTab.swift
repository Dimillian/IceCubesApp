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
  @Environment(Client.self) private var client
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
          if UIDevice.current.userInterfaceIdiom == .pad, !preferences.showiPadSecondaryColumn {
            SecondaryColumnToolbarItem()
          }
        }
    }
    .withSafariRouter()
    .environmentObject(routerPath)
    .onChange(of: $popToRootTab.wrappedValue) { oldValue, newValue in
      if newValue == .explore {
        routerPath.path = []
      }
    }
    .onChange(of: client.id) {
      routerPath.path = []
    }
    .onAppear {
      routerPath.client = client
    }
  }
}
