import Models
import NukeUI
import SwiftUI

public struct MediaUIAttachmentImageView: View {
  public let url: URL
  public let description: String?

  @GestureState private var zoom = 1.0

  private var accessibilityLabel: Text {
    if let description, !description.isEmpty {
      return Text(description)
    }
    return Text("accessibility.media.supported-type.image.label")
  }

  public init(url: URL, description: String? = nil) {
    self.url = url
    self.description = description
  }

  public var body: some View {
    MediaUIZoomableContainer {
      LazyImage(url: url) { state in
        if let image = state.image {
          image
            .resizable()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaledToFit()
            .padding(.horizontal, 8)
            .padding(.top, 44)
            .padding(.bottom, 32)
            .scaleEffect(zoom)
            .accessibilityLabel(accessibilityLabel)
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
