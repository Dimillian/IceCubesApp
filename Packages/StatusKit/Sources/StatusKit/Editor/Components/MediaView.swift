import AVKit
import DesignSystem
import Env
import MediaUI
import Models
import NukeUI
import SwiftUI

extension StatusEditor {
  @MainActor
  struct MediaView: View {
    @Environment(Theme.self) private var theme
    @Environment(CurrentInstance.self) private var currentInstance
    var viewModel: ViewModel
    @Binding var editingMediaContainer: MediaContainer?

    @State private var isErrorDisplayed: Bool = false

    @Namespace var mediaSpace
    @State private var scrollID: String?

    var body: some View {
      ScrollView(.horizontal, showsIndicators: showsScrollIndicators) {
        switch count {
        case 1: mediaLayout
        case 2: mediaLayout
        case 3: mediaLayout
        case 4: mediaLayout
        default: mediaLayout
        }
      }
      .scrollPosition(id: $scrollID, anchor: .trailing)
      .scrollClipDisabled()
      .padding(.horizontal, .layoutPadding)
      .frame(height: count > 0 ? containerHeight : 0)
      .animation(.spring(duration: 0.3), value: count)
      .onChange(of: count) { oldValue, newValue in
        if oldValue < newValue {
          Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.bouncy(duration: 0.5)) {
              scrollID = containers.last?.id
            }
          }
        }
      }
    }

    private var count: Int { viewModel.mediaContainers.count }
    private var containers: [MediaContainer] { viewModel.mediaContainers }
    private let containerHeight: CGFloat = 300
    private var containerWidth: CGFloat { containerHeight / 1.5 }

    #if targetEnvironment(macCatalyst)
      private var showsScrollIndicators: Bool { count > 1 }
      private var scrollBottomPadding: CGFloat?
    #else
      private var showsScrollIndicators: Bool = false
      private var scrollBottomPadding: CGFloat? = 0
    #endif

    init(viewModel: ViewModel, editingMediaContainer: Binding<StatusEditor.MediaContainer?>) {
      self.viewModel = viewModel
      _editingMediaContainer = editingMediaContainer
    }

    private func pixel(at index: Int) -> some View {
      Rectangle().frame(width: 0, height: 0)
        .matchedGeometryEffect(id: index, in: mediaSpace, anchor: .leading)
    }

    private var mediaLayout: some View {
      HStack(alignment: .center, spacing: count > 1 ? 8 : 0) {
        if count > 0 {
          if count == 1 {
            makeMediaItem(at: 0)
              .containerRelativeFrame(.horizontal, alignment: .leading)
          } else {
            makeMediaItem(at: 0)
          }
        } else { pixel(at: 0) }
        if count > 1 { makeMediaItem(at: 1) } else { pixel(at: 1) }
        if count > 2 { makeMediaItem(at: 2) } else { pixel(at: 2) }
        if count > 3 { makeMediaItem(at: 3) } else { pixel(at: 3) }
      }
      .padding(.bottom, scrollBottomPadding)
      .scrollTargetLayout()
    }

    private func makeMediaItem(at index: Int) -> some View {
      let container = viewModel.mediaContainers[index]

      return Menu {
        makeImageMenu(container: container)
      } label: {
        RoundedRectangle(cornerRadius: 8).fill(.clear)
          .overlay {
            if let attachement = container.mediaAttachment {
              makeRemoteMediaView(mediaAttachement: attachement)
            } else if container.image != nil {
              makeLocalImageView(container: container)
            } else if let error = container.error as? ServerError {
              makeErrorView(error: error)
            } else {
              placeholderView
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
      .frame(minWidth: count == 1 ? nil : containerWidth, maxWidth: 600)
      .id(container.id)
      .matchedGeometryEffect(id: container.id, in: mediaSpace, anchor: .leading)
      .matchedGeometryEffect(id: index, in: mediaSpace, anchor: .leading)
    }

    private func makeLocalImageView(container: MediaContainer) -> some View {
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

    private func makeRemoteMediaView(mediaAttachement: MediaAttachment) -> some View {
      ZStack(alignment: .center) {
        switch mediaAttachement.supportedType {
        case .gifv, .video, .audio:
          if let url = mediaAttachement.url {
            MediaUIAttachmentVideoView(viewModel: .init(url: url, forceAutoPlay: true))
          } else {
            placeholderView
          }
        case .image:
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
          }
        case .none:
          EmptyView()
        }
      }
      .cornerRadius(8)
    }

    @ViewBuilder
    private func makeImageMenu(container: MediaContainer) -> some View {
      if container.mediaAttachment?.url != nil {
        if currentInstance.isEditAltTextSupported || !viewModel.mode.isEditing {
          Button {
            editingMediaContainer = container
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

    private func makeAltMarker(container: MediaContainer) -> some View {
      Button {
        editingMediaContainer = container
      } label: {
        Text("status.image.alt-text.abbreviation")
          .font(.caption2)
      }
      .padding(8)
      .background(.thinMaterial)
      .cornerRadius(8)
      .padding(4)
    }

    private func makeDiscardMarker(container: MediaContainer) -> some View {
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

    private func deleteAction(container: MediaContainer) {
      viewModel.mediaPickers.removeAll(where: {
        if let id = $0.itemIdentifier {
          return id == container.id
        }
        return false
      })
      viewModel.mediaContainers.removeAll {
        $0.id == container.id
      }
    }

    private var placeholderView: some View {
      ZStack(alignment: .center) {
        Rectangle()
          .foregroundColor(theme.secondaryBackgroundColor)
          .accessibilityHidden(true)
        ProgressView()
      }
      .cornerRadius(8)
    }
  }
}
