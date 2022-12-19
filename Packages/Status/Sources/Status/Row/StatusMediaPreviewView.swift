import SwiftUI
import Models
import AVKit

// Could have just been a state, but SwiftUI .sheet is buggy ATM without @StateObject
class SelectedMediaSheetManager: ObservableObject {
  @Published var selectedAttachement: MediaAttachement?
}

public struct StatusMediaPreviewView: View {
  public let attachements: [MediaAttachement]
  
  @StateObject private var selectedMediaSheetManager = SelectedMediaSheetManager()

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
    .sheet(item: $selectedMediaSheetManager.selectedAttachement) { selectedAttachement in
      makeSelectedAttachementsSheet(selectedAttachement: selectedAttachement)
    }
  }
  
  @ViewBuilder
  private func makePreview(attachement: MediaAttachement) -> some View {
    if let type = attachement.supportedType {
      switch type {
      case .image:
        Group {
          GeometryReader { proxy in
            AsyncImage(
              url: attachement.url,
              content: { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(height: attachements.count > 2 ? 100 : 200)
                  .frame(width: proxy.frame(in: .local).width)
              },
              placeholder: {
                ProgressView()
                  .frame(maxWidth: 80, maxHeight: 80)
              }
            )
          }
          .frame(height: attachements.count > 2 ? 100 : 200)
        }
        .cornerRadius(4)
        .onTapGesture {
          selectedMediaSheetManager.selectedAttachement = attachement
        }
      case .gifv:
        VideoPlayer(player: AVPlayer(url: attachement.url))
          .frame(maxHeight: attachements.count > 2 ? 100 : 200)
      }
    }
  }
  
  
  private func makeSelectedAttachementsSheet(selectedAttachement: MediaAttachement) -> some View {
    var attachements = attachements
    attachements.removeAll(where: { $0.id == selectedAttachement.id })
    attachements.insert(selectedAttachement, at: 0)
    return TabView {
      ForEach(attachements) { attachement in
        VStack {
          Spacer()
          AsyncImage(
            url: attachement.url,
            content: { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            },
            placeholder: {
              ProgressView()
                .frame(maxWidth: 80, maxHeight: 80)
            }
          )
          Spacer()
        }
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
  }
}
