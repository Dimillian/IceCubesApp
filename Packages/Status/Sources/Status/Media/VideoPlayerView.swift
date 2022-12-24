import SwiftUI
import AVKit

class VideoPlayerViewModel: ObservableObject {
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

struct VideoPlayerView: View {
  @StateObject var viewModel: VideoPlayerViewModel
  var body: some View {
    VStack {
      VideoPlayer(player: viewModel.player)
    }.onAppear {
      viewModel.preparePlayer()
    }
  }
}
