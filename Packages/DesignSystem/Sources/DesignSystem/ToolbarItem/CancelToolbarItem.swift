import SwiftUI

public struct CancelToolbarItem: ToolbarContent {
  @Environment(\.dismiss) private var dismiss

  public init() {}

  public var body: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button(role: .cancel) {
        dismiss()
      } label: {
        Label("action.cancel", systemImage: "xmark")
      }
      .tint(.red)
    }
  }
}
