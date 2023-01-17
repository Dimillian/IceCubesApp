import SwiftUI
import Env
import Models
import DesignSystem
import NukeUI

struct StatusEditorMediaView: View {
  @EnvironmentObject private var theme: Theme
  @ObservedObject var viewModel: StatusEditorViewModel
  @State private var editingContainer: StatusEditorViewModel.ImageContainer?
  
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(viewModel.mediasImages) { container in
          Menu {
            makeImageMenu(container: container)
          } label: {
            ZStack(alignment: .bottomTrailing) {
              if container.image != nil {
                makeLocalImage(container: container)
              }  else if let url = container.mediaAttachement?.url ?? container.mediaAttachement?.previewUrl {
                makeLazyImage(url: url)
              }
              if container.mediaAttachement?.description?.isEmpty == false {
                altMarker
              }
            }
          }
        }
      }
      .padding(.horizontal, .layoutPadding)
    }
    .sheet(item: $editingContainer) { container in
      StatusEditorMediaEditView(viewModel: viewModel, container: container)
        .preferredColorScheme(theme.selectedScheme == .dark ? .dark : .light)
    }
  }
  
  private func makeLocalImage(container: StatusEditorViewModel.ImageContainer) -> some View {
    ZStack(alignment: .center) {
      Image(uiImage: container.image!)
        .resizable()
        .blur(radius: container.mediaAttachement == nil ? 20 : 0)
        .aspectRatio(contentMode: .fill)
        .frame(width: 150, height: 150)
        .cornerRadius(8)
      if container.error != nil {
        VStack {
          Text("Error uploading")
          Button {
            withAnimation {
              viewModel.mediasImages.removeAll(where: { $0.id == container.id })
            }
          } label: {
            VStack {
              Text("Delete")
            }
          }
          .buttonStyle(.bordered)
          Button {
            Task {
              await viewModel.upload(container: container)
            }
          } label: {
            VStack {
              Text("Retry")
            }
          }
          .buttonStyle(.bordered)
        }
      } else if container.mediaAttachement == nil{
        ProgressView()
      }
    }
  }
  
  private func makeLazyImage(url: URL?) -> some View {
    LazyImage(url: url) { state in
      if let image = state.image {
        image
          .resizingMode(.aspectFill)
          .frame(width: 150, height: 150)
      } else {
        Rectangle()
          .frame(width: 150, height: 150)
      }
    }
    .frame(width: 150, height: 150)
    .cornerRadius(8)
  }
  
  @ViewBuilder
  private func makeImageMenu(container: StatusEditorViewModel.ImageContainer) -> some View {
    if !viewModel.mode.isEditing {
      Button {
        editingContainer = container
      } label: {
        Label(container.mediaAttachement?.description?.isEmpty == false ?
              "Edit description" : "Add description",
              systemImage: "pencil.line")
      }
    }
    Button(role: .destructive) {
      withAnimation {
        viewModel.mediasImages.removeAll(where: { $0.id == container.id })
      }
    } label: {
      Label("Delete", systemImage: "trash")
    }
  }
  
  private var altMarker: some View {
    Button {
    } label: {
      Text("ALT")
        .font(.caption2)
    }
    .padding(4)
    .background(.thinMaterial)
    .cornerRadius(8)
  }
}
