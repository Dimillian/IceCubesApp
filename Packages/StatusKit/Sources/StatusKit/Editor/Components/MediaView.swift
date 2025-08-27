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
        } else {
          pixel(at: 0)
        }
        if count > 1 { makeMediaItem(at: 1) } else { pixel(at: 1) }
        if count > 2 { makeMediaItem(at: 2) } else { pixel(at: 2) }
        if count > 3 { makeMediaItem(at: 3) } else { pixel(at: 3) }
      }
      .padding(.bottom, scrollBottomPadding)
      .scrollTargetLayout()
    }

    @ViewBuilder
    private func makeMediaItem(at index: Int) -> some View {
      let container = viewModel.mediaContainers[index]

      RoundedRectangle(cornerRadius: 8)
        .fill(.clear)
        .overlay {
          switch container.state {
          case .pending(let content):
            makeLocalMediaView(content: content)
          case .uploading(let content, let progress):
            makeUploadingView(content: content, progress: progress)
          case .uploaded(let attachment, _):
            makeRemoteMediaView(mediaAttachement: attachment)
          case .failed(let content, let error):
            makeErrorView(content: content, error: error)
          }
        }
        .contextMenu {
          makeImageMenu(container: container)
        }
        .alert("alert.error", isPresented: $isErrorDisplayed) {
          Button("Ok", action: {})
        } message: {
          Text(container.error?.localizedDescription ?? "")
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

    private func makeLocalMediaView(content: MediaContainer.MediaContent) -> some View {
      ZStack(alignment: .center) {
        if let image = content.previewImage {
          Image(uiImage: image)
            .resizable()
            .blur(radius: 20)
            .scaledToFill()
            .cornerRadius(8)
        } else {
          placeholderView
        }
        ProgressView()
      }
    }
    
    private func makeUploadingView(content: MediaContainer.MediaContent, progress: Double) -> some View {
      ZStack(alignment: .center) {
        if let image = content.previewImage {
          Image(uiImage: image)
            .resizable()
            .blur(radius: 10)
            .scaledToFill()
            .cornerRadius(8)
        } else {
          placeholderView
        }
        VStack {
          if progress > 0 && progress < 1 {
            ProgressView(value: progress)
              .progressViewStyle(.linear)
              .padding(.horizontal)
          } else  {
            ProgressView()
                .progressViewStyle(.circular)
          }
        }
        .transition(.identity)
        .animation(.bouncy, value: progress)
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
      switch container.state {
      case .uploaded(let attachment, _):
        if attachment.url != nil {
          if currentInstance.isEditAltTextSupported || !viewModel.mode.isEditing {
            Button {
              editingMediaContainer = container
            } label: {
              Label(
                attachment.description?.isEmpty == false
                  ? "status.editor.description.edit" : "status.editor.description.add",
                systemImage: "pencil.line")
            }
          }
        }
      case .failed:
        Button {
          isErrorDisplayed = true
        } label: {
          Label("action.view.error", systemImage: "exclamationmark.triangle")
        }
      case .pending:
        Button {
          Task {
            await viewModel.upload(container: container)
          }
        } label: {
          Label("Retry Upload", systemImage: "arrow.clockwise")
        }
      case .uploading:
        EmptyView()
      }

      Button(role: .destructive) {
        deleteAction(container: container)
      } label: {
        Label("action.delete", systemImage: "trash")
      }
    }

    private func makeErrorView(content: MediaContainer.MediaContent, error: MediaContainer.MediaError) -> some View {
      ZStack {
        if let image = content.previewImage {
          Image(uiImage: image)
            .resizable()
            .blur(radius: 5)
            .scaledToFill()
            .cornerRadius(8)
            .opacity(0.5)
        } else {
          placeholderView
        }
        VStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
          Text("status.editor.error.upload")
            .font(.caption)
        }
      }
    }

    @ViewBuilder
    private func makeAltMarker(container: MediaContainer) -> some View {
      if #available(iOS 26.0, *) {
        Button {
          editingMediaContainer = container
        } label: {
          Text("status.image.alt-text.abbreviation")
            .font(.caption2)
            .padding(4)
        }
        .buttonStyle(.glass)
        .padding()
      } else {
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
    }

    @ViewBuilder
    private func makeDiscardMarker(container: MediaContainer) -> some View {
      if #available(iOS 26.0, *) {
        Button(role: .destructive) {
          deleteAction(container: container)
        } label: {
          Image(systemName: "xmark")
            .font(.caption2)
            .padding(4)
        }
        .buttonStyle(.glass)
        .padding()
      } else {
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
