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
    guard let player else { return }
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                           object: player.currentItem, queue: .main) { [weak self] _ in
        self?.player?.seek(to: CMTime.zero)
        self?.player?.play()
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.player)
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
  
  private var imageMaxHeight: CGFloat {
    if attachements.count == 1 {
      return 300
    }
    return attachements.count > 2 ? 100 : 200
  }
  
  public var body: some View {
    Group {
      if attachements.count == 1, let attachement = attachements.first {
        makeFeaturedImagePreview(attachement: attachement)
          .onTapGesture {
            Task {
              await quickLook.prepareFor(urls: attachements.map{ $0.url }, selectedURL: attachement.url)
            }
          }
      } else {
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
    }
    .overlay {
      if quickLook.isPreparing {
        quickLookLoadingView
          .transition(.opacity)
      }
    }
  }
  
  @ViewBuilder
  private func makeFeaturedImagePreview(attachement: MediaAttachement) -> some View {
    switch attachement.supportedType {
    case .image:
      AsyncImage(
        url: attachement.url,
        content: { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .cornerRadius(4)
        },
        placeholder: {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray)
            .frame(height: imageMaxHeight)
            .shimmering()
        }
      )
    case .gifv:
      VideoPlayerView(viewModel: .init(url: attachement.url))
        .frame(height: imageMaxHeight)
    case .none:
      EmptyView()
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
                  .aspectRatio(contentMode: attachements.count == 1 ? .fit : .fill)
                  .frame(height: imageMaxHeight)
                  .frame(width: proxy.frame(in: .local).width)
                  .cornerRadius(4)
              },
              placeholder: {
                RoundedRectangle(cornerRadius: 4)
                  .fill(Color.gray)
                  .frame(maxHeight: imageMaxHeight)
                  .frame(width: proxy.frame(in: .local).width)
                  .shimmering()
              }
            )
          case .gifv:
            VideoPlayerView(viewModel: .init(url: attachement.url))
              .frame(width: proxy.frame(in: .local).width)
              .frame(height: imageMaxHeight)
          }
        }
        .frame(height: imageMaxHeight)
      }
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
