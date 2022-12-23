import SwiftUI

public struct StatusEditorView: View {
  @Environment(\.dismiss) private var dismiss
  
  @State private var statusText: String = ""
  public init() {
    
  }
  
  public var body: some View {
    NavigationStack {
      Form {
        TextEditor(text: $statusText)
      }
      .navigationTitle("Post a toot")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Text("Post")
          }
        }
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            dismiss()
          } label: {
            Text("Cancel")
          }
        }
      }
    }
  }
}
