import AppAccount
import DesignSystem
import Env
import Explore
import Models
import Network
import SwiftUI

@MainActor
struct ExploreTab: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var preferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(Client.self) private var client
  @State private var routerPath = RouterPath()
  @State private var scrollToTopSignal: Int = 0
  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      ExploreView(scrollToTopSignal: $scrollToTopSignal)
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .navigationBar)
        .toolbar {
          ToolbarTab(routerPath: $routerPath)
        }
    }
    .withSafariRouter()
    .environment(routerPath)
    .onChange(of: $popToRootTab.wrappedValue) { _, newValue in
      if newValue == .explore {
        if routerPath.path.isEmpty {
          scrollToTopSignal += 1
        } else {
          routerPath.path = []
        }
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
