import AVKit
import DesignSystem
import Env
import Observation
import SwiftUI

@MainActor
@Observable class VideoPlayerViewModel {
  var player: AVPlayer?
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
                                           object: player.currentItem, queue: .main)
    { _ in
      Task { @MainActor [weak self] in
        if autoPlay {
          self?.play()
        }
      }
    }
  }

  func pause() {
    player?.pause()
  }

  func play() {
    player?.seek(to: CMTime.zero)
    player?.play()
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
  }
}

struct VideoPlayerView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.isCompact) private var isCompact
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme

  @State var viewModel: VideoPlayerViewModel

  var body: some View {
    ZStack {
      VideoPlayer(player: viewModel.player)
        .accessibilityAddTraits(.startsMediaSession)

      if !preferences.autoPlayVideo {
        Image(systemName: "play.fill")
          .font(isCompact ? .body : .largeTitle)
          .foregroundColor(theme.tintColor)
          .padding(.all, isCompact ? 6 : nil)
          .background(Circle().fill(.thinMaterial))
          .padding(theme.statusDisplayStyle == .compact ? 0 : 10)
      }
    }.onAppear {
      viewModel.preparePlayer(autoPlay: preferences.autoPlayVideo)
    }
    .onDisappear {
      viewModel.pause()
    }
    .cornerRadius(4)
    .onChange(of: scenePhase) { _, newValue in
      switch newValue {
      case .background, .inactive:
        viewModel.pause()
      case .active:
        if preferences.autoPlayVideo {
          viewModel.play()
        }
      default:
        break
      }
    }
  }
}
