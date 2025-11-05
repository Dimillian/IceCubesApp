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
        mediaLayout
      }
      .scrollPosition(id: $scrollID, anchor: .trailing)
      .scrollClipDisabled()
      .padding(.horizontal, .layoutPadding)
      .frame(height: viewModel.mediaContainers.count > 0 ? containerHeight : 0)
      .animation(.spring(duration: 0.3), value: viewModel.mediaContainers.count)
      .onChange(of: viewModel.mediaPickers.count) { oldValue, newValue in
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

    private var containers: [MediaContainer] { viewModel.mediaContainers }
    private let containerHeight: CGFloat = 300
    private var containerWidth: CGFloat { containerHeight / 1.5 }

    #if targetEnvironment(macCatalyst)
      private var scrollBottomPadding: CGFloat?
    #else
      private var scrollBottomPadding: CGFloat? = 0
    #endif
    
    private var showsScrollIndicators: Bool = false

    init(viewModel: ViewModel, editingMediaContainer: Binding<StatusEditor.MediaContainer?>) {
      self.viewModel = viewModel
      _editingMediaContainer = editingMediaContainer
    }

    private var mediaLayout: some View {
      HStack(alignment: .center, spacing: 8) {
        ForEach(Array(viewModel.mediaContainers.enumerated()), id: \.offset) { index, container in
          makeMediaItem(container)
            .containerRelativeFrame(.horizontal,
                                    count: viewModel.mediaContainers.count == 1 ? 1 : 2,
                                    span: 1,
                                    spacing: 0,
                                    alignment: .leading)
        }
      }
      .padding(.bottom, scrollBottomPadding)
      .scrollTargetLayout()
    }

    private func makeMediaItem(_ container: MediaContainer) -> some View {
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
        .contentShape(Rectangle())
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
        .id(container.id)
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
                  .clipped()
                  .allowsHitTesting(false)
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
