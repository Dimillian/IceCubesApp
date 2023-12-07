import AVKit
import DesignSystem
import Env
import Models
import NukeUI
import SwiftUI

@MainActor
struct StatusEditorMediaView: View {
  @Environment(Theme.self) private var theme
  @Environment(CurrentInstance.self) private var currentInstance
  var viewModel: StatusEditorViewModel
  @Binding var editingContainer: StatusEditorMediaContainer?

  @State private var isErrorDisplayed: Bool = false

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(viewModel.mediasImages) { container in
          Menu {
            makeImageMenu(container: container)
          } label: {
            if let attachement = container.mediaAttachment {
              makeLazyImage(mediaAttachement: attachement)
            } else if container.image != nil {
              makeLocalImage(container: container)
            } else if container.movieTransferable != nil || container.gifTransferable != nil {
              makeVideoAttachement(container: container)
            } else if let error = container.error as? ServerError {
              makeErrorView(error: error)
            }
          }
          .overlay(alignment: .bottomTrailing) {
            makeAltMarker(container: container)
          }
          .overlay(alignment: .topTrailing) {
            makeDiscardMarker(container: container)
          }
        }
      }
      .padding(.horizontal, .layoutPadding)
    }
  }

  private func makeVideoAttachement(container: StatusEditorMediaContainer) -> some View {
    ZStack(alignment: .center) {
      placeholderView
      if container.mediaAttachment == nil {
        ProgressView()
      }
    }
    .cornerRadius(8)
    .frame(width: 150, height: 150)
  }

  private func makeLocalImage(container: StatusEditorMediaContainer) -> some View {
    ZStack(alignment: .center) {
      Image(uiImage: container.image!)
        .resizable()
        .blur(radius: container.mediaAttachment == nil ? 20 : 0)
        .aspectRatio(contentMode: .fill)
        .frame(width: 150, height: 150)
        .cornerRadius(8)
      if container.error != nil {
        Text("status.editor.error.upload")
      } else if container.mediaAttachment == nil {
        ProgressView()
      }
    }
  }

  private func makeLazyImage(mediaAttachement: MediaAttachment) -> some View {
    ZStack(alignment: .center) {
      if let url = mediaAttachement.url ?? mediaAttachement.previewUrl {
        LazyImage(url: url) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 150, height: 150)
          } else {
            placeholderView
          }
        }
      } else {
        placeholderView
      }
      if mediaAttachement.url == nil {
        ProgressView()
      }
      if mediaAttachement.url != nil,
         mediaAttachement.supportedType == .video || mediaAttachement.supportedType == .gifv
      {
        Image(systemName: "play.fill")
          .font(.headline)
          .tint(.white)
      }
    }
    .frame(width: 150, height: 150)
    .cornerRadius(8)
  }

  @ViewBuilder
  private func makeImageMenu(container: StatusEditorMediaContainer) -> some View {
    if container.mediaAttachment?.url != nil {
      if currentInstance.isEditAltTextSupported || !viewModel.mode.isEditing {
        Button {
          editingContainer = container
        } label: {
          Label(container.mediaAttachment?.description?.isEmpty == false ?
            "status.editor.description.edit" : "status.editor.description.add",
            systemImage: "pencil.line")
        }
      }
    } else if container.error != nil {
      Button {
        isErrorDisplayed = true
      } label: {
        Label("action.view.error", systemImage: "exclamationmark.triangle")
      }
    }

    Button(role: .destructive) {
      withAnimation {
        viewModel.selectedMedias.removeAll(where: {
          if let id = $0.itemIdentifier {
            return id == container.id
          }
          return false
        })

      }
    } label: {
      Label("action.delete", systemImage: "trash")
    }
  }

  private func makeErrorView(error: ServerError) -> some View {
    ZStack {
      placeholderView
      Text("status.editor.error.upload")
    }
    .alert("alert.error", isPresented: $isErrorDisplayed) {
      Button("Ok", action: {})
    } message: {
      Text(error.error ?? "")
    }
  }

  private func makeAltMarker(container: StatusEditorMediaContainer) -> some View {
    Button {
      editingContainer = container
    } label: {
      Text("status.image.alt-text.abbreviation")
        .font(.caption2)
    }
    .padding(4)
    .background(.thinMaterial)
    .cornerRadius(8)
    .padding(4)
  }

  private func makeDiscardMarker(container: StatusEditorMediaContainer) -> some View {
    Button(role: .destructive) {
      withAnimation {
        viewModel.selectedMedias.removeAll(where: {
          if let id = $0.itemIdentifier {
            return id == container.id
          }
          return false
        })
      }
    } label: {
      Image(systemName: "xmark")
        .font(.caption2)
        .foregroundStyle(.tint)
        .padding(4)
        .background(Circle().fill(.thinMaterial))
    }
    .padding(4)
  }

  private var placeholderView: some View {
    Rectangle()
      .foregroundColor(theme.secondaryBackgroundColor)
      .frame(width: 150, height: 150)
      .accessibilityHidden(true)
  }
}
