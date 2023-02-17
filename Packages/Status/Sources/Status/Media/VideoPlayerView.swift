import AVKit
import Env
import SwiftUI

class VideoPlayerViewModel: ObservableObject {
  @Published var player: AVPlayer?
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  func preparePlayer(autoPlay: Bool) {
    player = .init(url: url)
    player?.isMuted = true
    player?.audiovisualBackgroundPlaybackPolicy = .pauses
    if autoPlay {
      player?.play()
    } else {
      player?.pause()
    }
    guard let player else { return }
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                           object: player.currentItem, queue: .main) { [weak self] _ in
      if autoPlay {
        self?.player?.seek(to: CMTime.zero)
        self?.player?.play()
      }
    }
  }

  func pause() {
    player?.pause()
  }

  func play() {
    player?.play()
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.player)
  }
}

struct VideoPlayerView: View {
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var preferences: UserPreferences

  @StateObject var viewModel: VideoPlayerViewModel

  var body: some View {
    VStack {
      VideoPlayer(player: viewModel.player)
    }.onAppear {
      viewModel.preparePlayer(autoPlay: preferences.autoPlayVideo)
    }
    .cornerRadius(4)
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .background, .inactive:
        viewModel.pause()
      case .active:
        if preferences.autoPlayVideo {
          viewModel.play()
        }
      default:
        break
      }
    })
  }
}
