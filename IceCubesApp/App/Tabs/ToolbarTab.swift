import AppAccount
import DesignSystem
import Env
import SwiftUI

@MainActor
struct ToolbarTab: ToolbarContent {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Environment(UserPreferences.self) private var userPreferences

  @Binding var routerPath: RouterPath

  var body: some ToolbarContent {
    if !isSecondaryColumn {
      statusEditorToolbarItem(
        routerPath: routerPath,
        visibility: userPreferences.postVisibility)
      if #available(iOS 26.0, *) {
        ToolbarItem(placement: .navigationBarLeading) {
          AppAccountsSelectorView(
            routerPath: routerPath,
            avatarConfig: .embed)
            .offset(x: -12)
        }
        .sharedBackgroundVisibility(.hidden)
      } else {
        ToolbarItem(placement: .navigationBarLeading) {
          AppAccountsSelectorView(
            routerPath: routerPath,
            avatarConfig: .embed)
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
