import SwiftUI
import Models

public struct StatusMediaPreviewView: View {
  public let attachements: [MediaAttachement]

  public var body: some View {
    VStack {
      HStack {
        if let firstAttachement = attachements.first {
          makePreviewImage(attachement: firstAttachement)
        }
        if attachements.count > 1, let secondAttachement = attachements[1] {
          makePreviewImage(attachement: secondAttachement)
        }
      }
      HStack {
        if attachements.count > 2, let secondAttachement = attachements[2] {
          makePreviewImage(attachement: secondAttachement)
        }
        if attachements.count > 3, let secondAttachement = attachements[3] {
          makePreviewImage(attachement: secondAttachement)
        }
      }
    }
  }
  
  private func makePreviewImage(attachement: MediaAttachement) -> some View {
    AsyncImage(
      url: attachement.url,
      content: { image in
        image.resizable()
          .aspectRatio(contentMode: .fill)
          .frame(maxHeight: attachements.count > 2 ? 100 : 200)
          .clipped()
          .cornerRadius(4)
      },
      placeholder: {
        ProgressView()
          .frame(maxWidth: 80, maxHeight: 80)
      }
    )
  }
}
