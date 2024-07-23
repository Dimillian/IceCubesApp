import Models
import NukeUI
import SwiftUI

struct MediaUIAttachmentImageView: View {
  let url: URL

  @GestureState private var zoom = 1.0

  var body: some View {
    MediaUIZoomableContainer {
      LazyImage(url: url) { state in
        if let image = state.image {
          image
            .resizable()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaledToFit()
            .padding(.horizontal, 8)
            .scaleEffect(zoom)
        } else if state.isLoading {
          ProgressView()
            .progressViewStyle(.circular)
        }
      }
      .draggable(MediaUIImageTransferable(url: url))
      .contextMenu {
        MediaUIShareLink(url: url, type: .image)
        Button {
          Task {
            let transferable = MediaUIImageTransferable(url: url)
            UIPasteboard.general.image = UIImage(data: await transferable.fetchData())
          }
        } label: {
          Label("status.media.contextmenu.copy", systemImage: "doc.on.doc")
        }
        Button {
          UIPasteboard.general.url = url
        } label: {
          Label("status.action.copy-link", systemImage: "link")
        }
      }
    }
  }
}
