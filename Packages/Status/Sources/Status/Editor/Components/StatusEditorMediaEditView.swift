import DesignSystem
import Models
import Shimmer
import SwiftUI

struct StatusEditorMediaEditView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var theme: Theme
  @ObservedObject var viewModel: StatusEditorViewModel
  let container: StatusEditorMediaContainer

  @State private var imageDescription: String = ""

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("status.editor.media.image-description",
                    text: $imageDescription,
                    axis: .vertical)
        }
        .listRowBackground(theme.primaryBackgroundColor)
        Section {
          if let url = container.mediaAttachment?.url {
            AsyncImage(
              url: url,
              content: { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .cornerRadius(8)
                  .padding(8)
              },
              placeholder: {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.gray)
                  .frame(height: 200)
                  .shimmering()
              }
            )
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .onAppear {
        imageDescription = container.mediaAttachment?.description ?? ""
      }
      .navigationTitle("status.editor.media.edit-image")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("action.done") {
            if !imageDescription.isEmpty {
              Task {
                await viewModel.addDescription(container: container, description: imageDescription)
              }
            }
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarLeading) {
          Button("action.cancel") {
            dismiss()
          }
        }
      }
    }
  }
}
