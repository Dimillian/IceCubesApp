import DesignSystem
import Env
import Models
import Shimmer
import SwiftUI

struct StatusEditorMediaEditView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentInstance: CurrentInstance
  @ObservedObject var viewModel: StatusEditorViewModel
  let container: StatusEditorMediaContainer

  @State private var imageDescription: String = ""
  @FocusState private var isFieldFocused: Bool

  @State private var isUpdating: Bool = false

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("status.editor.media.image-description",
                    text: $imageDescription,
                    axis: .vertical)
            .focused($isFieldFocused)
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
        isFieldFocused = true
      }
      .navigationTitle("status.editor.media.edit-image")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            if !imageDescription.isEmpty {
              isUpdating = true
              if currentInstance.isEditAltTextSupported && viewModel.mode.isEditing {
                Task {
                  await viewModel.editDescription(container: container, description: imageDescription)
                  dismiss()
                  isUpdating = false
                }
              } else {
                Task {
                  await viewModel.addDescription(container: container, description: imageDescription)
                  dismiss()
                  isUpdating = false
                }
              }
            }
          } label: {
            if isUpdating {
              ProgressView()
            } else {
              Text("action.done")
            }
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
