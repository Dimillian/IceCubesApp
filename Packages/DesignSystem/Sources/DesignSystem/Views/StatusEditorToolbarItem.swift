import Env
import Models
import SwiftUI

@MainActor
public extension View {
  func statusEditorToolbarItem(routerPath: RouterPath, visibility: Models.Visibility) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        let feedback = UISelectionFeedbackGenerator()
        routerPath.presentedSheet = .newStatusEditor(visibility: visibility)
        feedback.selectionChanged()
      } label: {
        Image(systemName: "square.and.pencil")
      }
    }
  }
}

public struct StatusEditorToolbarItem: ToolbarContent {
  @EnvironmentObject private var routerPath: RouterPath

  let visibility: Models.Visibility
  let feedbackGenerator = UISelectionFeedbackGenerator()

  public init(visibility: Models.Visibility) {
    self.visibility = visibility
  }

  public var body: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        routerPath.presentedSheet = .newStatusEditor(visibility: visibility)
        feedbackGenerator.selectionChanged()
      } label: {
        Image(systemName: "square.and.pencil")
      }
    }
  }
}
