import SwiftUI
import Env

@MainActor
extension View {
  public func statusEditorToolbarItem(routeurPath: RouterPath) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        routeurPath.presentedSheet = .newStatusEditor
      } label: {
        Image(systemName: "square.and.pencil")
      }
    }
  }
}

public struct StatusEditorToolbarItem: ToolbarContent {
  @EnvironmentObject private var routerPath: RouterPath
  
  public init() { }
  
  public var body: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        routerPath.presentedSheet = .newStatusEditor
      } label: {
        Image(systemName: "square.and.pencil")
      }
    }
  }
}
