import SwiftUI
import Models
import DesignSystem
import Shimmer

struct StatusEditorMediaEditView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var theme: Theme
  @ObservedObject var viewModel: StatusEditorViewModel
  let container: StatusEditorViewModel.ImageContainer
  
  @State private var imageDescription: String = ""
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Image description", text: $imageDescription, axis: .horizontal)
        }
        .listRowBackground(theme.primaryBackgroundColor)
        Section {
          if let url = container.mediaAttachement?.url {
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
              })
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .onAppear {
        imageDescription = container.mediaAttachement?.description ?? ""
      }
      .navigationTitle("Edit Image")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            if !imageDescription.isEmpty {
              Task {
                await viewModel.addDescription(container: container, description: imageDescription)
              }
            }
            dismiss()
          }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }
}
