import Env
import Models
import SwiftUI

@MainActor
public extension View {
  func statusEditorToolbarItem(routerPath: RouterPath, visibility: Models.Visibility) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        routerPath.presentedSheet = .newStatusEditor(visibility: visibility)
        HapticManager.shared.fireHaptic(of: .buttonPress)
      } label: {
        Image(systemName: "square.and.pencil")
          .accessibilityLabel("accessibility.tabs.timeline.new-post.label")
          .accessibilityInputLabels([
            LocalizedStringKey("accessibility.tabs.timeline.new-post.label"),
            LocalizedStringKey("accessibility.tabs.timeline.new-post.inputLabel1"),
            LocalizedStringKey("accessibility.tabs.timeline.new-post.inputLabel2"),
          ])
      }
    }
  }
}

public struct StatusEditorToolbarItem: ToolbarContent {
  @EnvironmentObject private var routerPath: RouterPath

  let visibility: Models.Visibility

  public init(visibility: Models.Visibility) {
    self.visibility = visibility
  }

  public var body: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        routerPath.presentedSheet = .newStatusEditor(visibility: visibility)
        HapticManager.shared.fireHaptic(of: .buttonPress)
      } label: {
        Image(systemName: "square.and.pencil")
          .accessibilityLabel("accessibility.tabs.timeline.new-post.label")
          .accessibilityInputLabels([
            LocalizedStringKey("accessibility.tabs.timeline.new-post.label"),
            LocalizedStringKey("accessibility.tabs.timeline.new-post.inputLabel1"),
            LocalizedStringKey("accessibility.tabs.timeline.new-post.inputLabel2"),
          ])
      }
    }
  }
}

public struct SecondaryColumnToolbarItem: ToolbarContent {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn
  @EnvironmentObject private var preferences: UserPreferences

  public init() {}

  public var body: some ToolbarContent {
    ToolbarItem(placement: isSecondaryColumn ? .navigationBarLeading : .navigationBarTrailing) {
      Button {
        withAnimation {
          preferences.showiPadSecondaryColumn.toggle()
        }
      } label: {
        Image(systemName: "sidebar.right")
      }
    }
  }
}
