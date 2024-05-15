import DesignSystem
import Env
import Models
import Network
import SwiftUI

extension StatusEditor {
  @MainActor
  struct MediaEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Theme.self) private var theme
    @Environment(CurrentInstance.self) private var currentInstance
    @Environment(UserPreferences.self) private var preferences

    var viewModel: ViewModel
    let container: StatusEditor.MediaContainer

    @State private var imageDescription: String = ""
    @FocusState private var isFieldFocused: Bool

    @State private var isUpdating: Bool = false

    @State private var didAppear: Bool = false
    @State private var isGeneratingDescription: Bool = false

    @State private var showTranslateView: Bool = false
    @State private var isTranslating: Bool = false

    var body: some View {
      NavigationStack {
        Form {
          Section {
            TextField("status.editor.media.image-description",
                      text: $imageDescription,
                      axis: .vertical)
              .focused($isFieldFocused)
            if imageDescription.isEmpty {
              generateButton
            }
            #if canImport(_Translation_SwiftUI)
            if #available(iOS 17.4, *), !imageDescription.isEmpty {
              translateButton
            }
            #endif
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

          CancelToolbarItem()
        }
        .preferredColorScheme(theme.selectedScheme == .dark ? .dark : .light)
      }
    }

    @ViewBuilder
    private var generateButton: some View {
      if let url = container.mediaAttachment?.url, preferences.isOpenAIEnabled {
        Button {
          Task {
            if let description = await generateDescription(url: url) {
              imageDescription = description
            }
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

    @ViewBuilder
    private var translateButton: some View {
      Button {
        showTranslateView = true
      } label: {
        if isTranslating {
          ProgressView()
        } else {
          Text("status.action.translate")
        }
      }
      #if canImport(_Translation_SwiftUI)
      .addTranslateView(isPresented: $showTranslateView, text: imageDescription)
      #endif
    }

    private func generateDescription(url: URL) async -> String? {
      isGeneratingDescription = true
      let client = OpenAIClient()
      let response = try? await client.request(.imageDescription(image: url))
      isGeneratingDescription = false
      return response?.trimmedText
    }
  }
}
