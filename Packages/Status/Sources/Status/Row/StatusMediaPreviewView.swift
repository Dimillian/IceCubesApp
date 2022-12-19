import SwiftUI
import Models
import AVKit

public struct StatusMediaPreviewView: View {
  public let attachements: [MediaAttachement]

  public var body: some View {
    VStack {
      HStack {
        if let firstAttachement = attachements.first {
          makePreview(attachement: firstAttachement)
        }
        if attachements.count > 1, let secondAttachement = attachements[1] {
          makePreview(attachement: secondAttachement)
        }
      }
      HStack {
        if attachements.count > 2, let secondAttachement = attachements[2] {
          makePreview(attachement: secondAttachement)
        }
        if attachements.count > 3, let secondAttachement = attachements[3] {
          makePreview(attachement: secondAttachement)
        }
      }
    }
  }
  
  @ViewBuilder
  private func makePreview(attachement: MediaAttachement) -> some View {
    if let type = attachement.supportedType {
      switch type {
      case .image:
        AsyncImage(
          url: attachement.url,
          content: { image in
            image.resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxHeight: attachements.count > 2 ? 100 : 200)
              .clipped()
              .cornerRadius(4)
          },
          placeholder: {
            ProgressView()
              .frame(maxWidth: 80, maxHeight: 80)
          }
        )
      case .gifv:
        VideoPlayer(player: AVPlayer(url: attachement.url))
          .frame(maxHeight: attachements.count > 2 ? 100 : 200)
      }
    }
  }
}
