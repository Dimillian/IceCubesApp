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
      ToolbarItem(placement: .topBarLeading) {
        if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
          Button {
            withAnimation {
              userPreferences.isSidebarExpanded.toggle()
            }
          } label: {
            if userPreferences.isSidebarExpanded {
              Image(systemName: "sidebar.squares.left")
            } else {
              Image(systemName: "sidebar.left")
            }
          }
        }
      }
      statusEditorToolbarItem(routerPath: routerPath,
                              visibility: userPreferences.postVisibility)
      if UIDevice.current.userInterfaceIdiom != .pad ||
        (UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .compact)
      {
        ToolbarItem(placement: .navigationBarLeading) {
          AppAccountsSelectorView(routerPath: routerPath, avatarConfig: theme.avatarShape == .circle ? .badge : .badgeRounded)
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
