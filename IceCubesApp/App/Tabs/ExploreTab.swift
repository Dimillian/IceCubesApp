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

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      ExploreView()
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          ToolbarTab(routerPath: $routerPath)
        }
    }
    .withSafariRouter()
    .environment(routerPath)
    .onChange(of: client.id) {
      routerPath.path = []
    }
    .onAppear {
      routerPath.client = client
    }
  }
}
