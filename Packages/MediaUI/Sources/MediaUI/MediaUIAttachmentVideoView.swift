import AVKit
import DesignSystem
import Env
import Observation
import SwiftUI

@MainActor
@Observable public class MediaUIAttachmentVideoViewModel {
  var player: AVPlayer?
  private let url: URL
  let forceAutoPlay: Bool

  public init(url: URL, forceAutoPlay: Bool = false) {
    self.url = url
    self.forceAutoPlay = forceAutoPlay
  }

  func preparePlayer(autoPlay: Bool) {
    player = .init(url: url)
    player?.isMuted = !forceAutoPlay
    player?.audiovisualBackgroundPlaybackPolicy = .pauses
    if autoPlay || forceAutoPlay {
      player?.play()
    } else {
      player?.pause()
    }
    guard let player else { return }
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                           object: player.currentItem, queue: .main)
    { _ in
      Task { @MainActor [weak self] in
        if autoPlay || self?.forceAutoPlay == true {
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

public struct MediaUIAttachmentVideoView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.isCompact) private var isCompact
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme

  @State var viewModel: MediaUIAttachmentVideoViewModel

  public init(viewModel: MediaUIAttachmentVideoViewModel) {
    _viewModel = .init(wrappedValue: viewModel)
  }

  public var body: some View {
    ZStack {
      VideoPlayer(player: viewModel.player)
        .accessibilityAddTraits(.startsMediaSession)

      if !preferences.autoPlayVideo, !viewModel.forceAutoPlay {
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
        if preferences.autoPlayVideo || viewModel.forceAutoPlay {
          viewModel.play()
        }
      default:
        break
      }
    }
  }
}
