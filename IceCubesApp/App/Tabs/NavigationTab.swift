import SwiftUI
import Env
import AppAccount
import DesignSystem

@MainActor
struct NavigationTab<Content: View>: View {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  
  @Environment(AppAccountsManager.self) private var appAccount
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  
  var content: () -> Content
  
  @State private var routerPath = RouterPath()
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    NavigationStack(path: $routerPath.path) {
      content()
        .withEnvironments()
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          ToolbarTab(routerPath: $routerPath)
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
    }
    .environment(routerPath)
  }
}
