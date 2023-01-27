import AVKit
import DesignSystem
import Env
import Models
import NukeUI
import SwiftUI

struct StatusEditorMediaView: View {
  @EnvironmentObject private var theme: Theme
  @ObservedObject var viewModel: StatusEditorViewModel
  @State private var editingContainer: StatusEditorMediaContainer?

  @State private var isErrorDisplayed: Bool = false

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(viewModel.mediasImages) { container in
          Menu {
            makeImageMenu(container: container)
          } label: {
            ZStack(alignment: .bottomTrailing) {
              if let attachement = container.mediaAttachment {
                makeLazyImage(mediaAttachement: attachement)
              } else if container.image != nil {
                makeLocalImage(container: container)
              } else if container.movieTransferable != nil {
                makeVideoAttachement(container: container)
              } else if let error = container.error as? ServerError {
                makeErrorView(error: error)
              }
              if container.mediaAttachment?.description?.isEmpty == false {
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
        VStack {
          Text("status.editor.error.upload")
          Button {
            withAnimation {
              viewModel.mediasImages.removeAll(where: { $0.id == container.id })
            }
          } label: {
            VStack {
              Text("action.delete")
            }
          }
          .buttonStyle(.bordered)
          Button {
            Task {
              await viewModel.upload(container: container)
            }
          } label: {
            VStack {
              Text("action.retry")
            }
          }
          .buttonStyle(.bordered)
        }
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
              .resizingMode(.aspectFill)
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
    if container.mediaAttachment != nil {
      if !viewModel.mode.isEditing {
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
        viewModel.mediasImages.removeAll(where: { $0.id == container.id })
      }
    } label: {
      Label("action.delete", systemImage: "trash")
    }
  }

  private func makeErrorView(error: ServerError) -> some View {
    ZStack {
      placeholderView
      Text("alert.error")
        .foregroundColor(.red)
    }
    .alert("alert.error", isPresented: $isErrorDisplayed) {
      Button("Ok", action: {})
    } message: {
      Text(error.error ?? "")
    }
  }

  private var altMarker: some View {
    Button {} label: {
      Text("status.image.alt-text.abbreviation")
        .font(.caption2)
    }
    .padding(4)
    .background(.thinMaterial)
    .cornerRadius(8)
  }

  private var placeholderView: some View {
    Rectangle()
      .foregroundColor(theme.secondaryBackgroundColor)
      .frame(width: 150, height: 150)
  }
}
