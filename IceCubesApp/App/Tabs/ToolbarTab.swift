import SwiftUI
import Env
import AppAccount
import DesignSystem
import Explore

@MainActor
struct ToolbarTab: ToolbarContent {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  @Environment(UserPreferences.self) private var userPreferences
  
  @Binding var routerPath: RouterPath
  @State private var scrollToTopSignal: Int = 0

  var body: some ToolbarContent {
    if !isSecondaryColumn {
        ToolbarItem {
            NavigationLink(destination: ExploreView(scrollToTopSignal: $scrollToTopSignal)) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.shared.labelColor)
            }
        }
    }
    if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
      if (!isSecondaryColumn && !userPreferences.showiPadSecondaryColumn) || isSecondaryColumn {
        SecondaryColumnToolbarItem()
      }
    }
  }
}
