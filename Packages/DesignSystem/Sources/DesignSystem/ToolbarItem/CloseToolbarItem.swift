import SwiftUI

public struct CloseToolbarItem: ToolbarContent {
  @Environment(\.dismiss) private var dismiss

  public init() {}

  public var body: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button(
        action: {
          dismiss()
        },
        label: {
          Image(systemName: "xmark.circle")
        }
      )
      .keyboardShortcut(.cancelAction)
    }
  }
}
