import DesignSystem
import Env
import Models
import Shimmer
import SwiftUI
import Network

struct StatusEditorMediaEditView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(UserPreferences.self) private var preferences
  
  var viewModel: StatusEditorViewModel
  let container: StatusEditorMediaContainer

  @State private var imageDescription: String = ""
  @FocusState private var isFieldFocused: Bool

  @State private var isUpdating: Bool = false

  @State private var didAppear: Bool = false
  @State private var isGeneratingDescription: Bool = false

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("status.editor.media.image-description",
                    text: $imageDescription,
                    axis: .vertical)
            .focused($isFieldFocused)
          if let url = container.mediaAttachment?.url, preferences.isOpenAIEnabled {
            Button {
              isGeneratingDescription = true
              Task {
                let client = OpenAIClient()
                let response = try await client.request(.imageDescription(image: url))
                imageDescription = response.trimmedText
                isGeneratingDescription = false
              }
            } label: {
              if isGeneratingDescription {
                ProgressView()
              } else {
                Text("status.editor.media.generate-description")
              }
            }
          }
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
        if !didAppear {
          imageDescription = container.mediaAttachment?.description ?? ""
          isFieldFocused = true
          didAppear = true
        }
      }
      .navigationTitle("status.editor.media.edit-image")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            if !imageDescription.isEmpty {
              isUpdating = true
              if currentInstance.isEditAltTextSupported, viewModel.mode.isEditing {
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
