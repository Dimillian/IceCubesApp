import Env
import Models
import SwiftUI

@MainActor
public extension View {
  func statusEditorToolbarItem(routerPath: RouterPath, visibility: Models.Visibility) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        routerPath.presentedSheet = .newStatusEditor(visibility: visibility)
      } label: {
        Image(systemName: "square.and.pencil")
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
      } label: {
        Image(systemName: "square.and.pencil")
      }
    }
  }
}
