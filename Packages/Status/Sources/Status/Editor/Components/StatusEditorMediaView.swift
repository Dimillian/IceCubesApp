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

  @Namespace var mediaSpace

  var body: some View {
    Group {
      switch count {
      case 1: mediaLayout
      case 2: mediaLayout
      case 3: mediaLayout
      case 4: mediaLayout
      default: mediaLayout
      }
    }
    .padding(.horizontal, .layoutPadding)
    .frame(minWidth: 300, idealWidth: 450, minHeight: 200, idealHeight: 250)
    .animation(.spring(duration: 0.3), value: count)
  }

  private var count: Int { viewModel.mediaContainers.count }
  private var containers: [StatusEditorMediaContainer] { viewModel.mediaContainers }

  private func pixel(at index: Int) -> some View {
    Rectangle().frame(width: 0, height: 0)
      .matchedGeometryEffect(id: 0, in: mediaSpace)
  }

  // TODO: add match geo
  // TODO: try 2 name space
  // TODO: refactor pixel into makeMediaItem
  private var mediaLayout: some View {
    HStack(spacing: count > 1 ? 8 : 0) {
      VStack(spacing: count > 3 ? 8 : 0) {
        if count > 0 { makeMediaItem(at: 0) } else { pixel(at: 0) }
        if count > 3 { makeMediaItem(at: 3) } else { pixel(at: 3) }
      }
      VStack(spacing: count > 2 ? 8 : 0) {
        if count > 1 { makeMediaItem(at: 1) } else { pixel(at: 1) }
        if count > 2 { makeMediaItem(at: 2) } else { pixel(at: 2) }
      }
    }
  }

  private func makeMediaItem(at index: Int) -> some View {
    let container = viewModel.mediaContainers[index]

    return Menu {
      makeImageMenu(container: container)
    } label: {
      RoundedRectangle(cornerRadius: 8).fill(.clear)
        .overlay {
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
    }
    .overlay(alignment: .bottomTrailing) {
      makeAltMarker(container: container)
    }
    .overlay(alignment: .topTrailing) {
      makeDiscardMarker(container: container)
    }
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .matchedGeometryEffect(id: container.id, in: mediaSpace)
    .matchedGeometryEffect(id: index, in: mediaSpace)
  }

  private func makeVideoAttachement(container: StatusEditorMediaContainer) -> some View {
    ZStack(alignment: .center) {
      placeholderView
      if container.mediaAttachment == nil {
        ProgressView()
      }
    }
    .cornerRadius(8)
  }

  private func makeLocalImage(container: StatusEditorMediaContainer) -> some View {
    ZStack(alignment: .center) {
      Image(uiImage: container.image!)
        .resizable()
        .blur(radius: container.mediaAttachment == nil ? 20 : 0)
        .scaledToFill()
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
              .scaledToFill()
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
      deleteAction(container: container)
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
    .padding(8)
    .background(.thinMaterial)
    .cornerRadius(8)
    .padding(4)
  }

  private func makeDiscardMarker(container: StatusEditorMediaContainer) -> some View {
    Button(role: .destructive) {
      deleteAction(container: container)
    } label: {
      Image(systemName: "xmark")
        .font(.caption2)
        .foregroundStyle(.tint)
        .padding(8)
        .background(Circle().fill(.thinMaterial))
    }
    .padding(4)
  }

  private func deleteAction(container: StatusEditorMediaContainer) {
    viewModel.mediaPickers.removeAll(where: {
      if let id = $0.itemIdentifier {
        return id == container.id
      }
      return false
    })
  }

  private var placeholderView: some View {
    Rectangle()
      .foregroundColor(theme.secondaryBackgroundColor)
      .accessibilityHidden(true)
  }
}
