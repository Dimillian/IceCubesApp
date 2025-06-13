import AppAccount
import DesignSystem
import Env
import SwiftUI

@MainActor
struct ToolbarTab: ToolbarContent {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme

  @Binding var routerPath: RouterPath

  var body: some ToolbarContent {
    if !isSecondaryColumn {
      statusEditorToolbarItem(
        routerPath: routerPath,
        visibility: userPreferences.postVisibility)
      ToolbarItem(placement: .navigationBarLeading) {
        AppAccountsSelectorView(
          routerPath: routerPath,
          avatarConfig: theme.avatarShape == .circle ? .badge : .badgeRounded)
      }
    }
    if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
      if (!isSecondaryColumn && !userPreferences.showiPadSecondaryColumn) || isSecondaryColumn {
        SecondaryColumnToolbarItem()
      }
    }
  }
}
