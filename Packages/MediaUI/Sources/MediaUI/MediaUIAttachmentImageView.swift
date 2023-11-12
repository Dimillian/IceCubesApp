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
    }
  }
}
