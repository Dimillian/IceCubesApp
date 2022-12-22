import SwiftUI
import Models
import AVKit
import Env
import Shimmer

private class VideoPlayerViewModel: ObservableObject {
  @Published var player: AVPlayer?
  private let url: URL
  
  init(url: URL) {
    self.url = url
  }
  
  func preparePlayer() {
    player = .init(url: url)
    player?.play()
  }
}

private struct VideoPlayerView: View {
  @StateObject var viewModel: VideoPlayerViewModel
  var body: some View {
    VStack {
      VideoPlayer(player: viewModel.player)
    }.onAppear {
      viewModel.preparePlayer()
    }
  }
}

// Could have just been a state, but SwiftUI .sheet is buggy ATM without @StateObject
private class SelectedMediaSheetManager: ObservableObject {
  @Published var selectedAttachement: MediaAttachement?
}

public struct StatusMediaPreviewView: View {
  @EnvironmentObject private var quickLook: QuickLook
  
  public let attachements: [MediaAttachement]
  
  @StateObject private var selectedMediaSheetManager = SelectedMediaSheetManager()
  
  @State private var isQuickLookLoading: Bool = false

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
    .overlay {
      if quickLook.isPreparing {
       quickLookLoadingView
          .transition(.opacity)
      }
    }

  }
  
  @ViewBuilder
  private func makePreview(attachement: MediaAttachement) -> some View {
    if let type = attachement.supportedType {
      Group {
        GeometryReader { proxy in
          switch type {
          case .image:
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
                RoundedRectangle(cornerRadius: 4)
                  .fill(Color.gray)
                  .frame(height: attachements.count > 2 ? 100 : 200)
                  .frame(width: proxy.frame(in: .local).width)
                  .shimmering()
              }
            )
          case .gifv:
            VideoPlayerView(viewModel: .init(url: attachement.url))
              .frame(width: proxy.frame(in: .local).width)
              .frame(height: attachements.count > 2 ? 100 : 200)
          }
        }
        .frame(height: attachements.count > 2 ? 100 : 200)
      }
      .cornerRadius(4)
      .contentShape(Rectangle())
      .onTapGesture {
        Task {
          await quickLook.prepareFor(urls: attachements.map{ $0.url }, selectedURL: attachement.url)
        }
      }
    }
  }
  
  private var quickLookLoadingView: some View {
    ZStack(alignment: .center) {
      VStack {
        Spacer()
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        Spacer()
      }
    }
    .background(.ultraThinMaterial)
  }
}
