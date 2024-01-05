import SwiftUI
import Env
import AppAccount
import DesignSystem

@MainActor
struct ToolbarTab: ToolbarContent {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  @Environment(UserPreferences.self) private var userPreferences
  
  @Binding var routerPath: RouterPath
  
  var body: some ToolbarContent {
    if !isSecondaryColumn {
      statusEditorToolbarItem(routerPath: routerPath,
                              visibility: userPreferences.postVisibility)
      if UIDevice.current.userInterfaceIdiom != .pad ||
          (UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .compact) {
        ToolbarItem(placement: .navigationBarLeading) {
          AppAccountsSelectorViewButton(routerPath: routerPath)
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
