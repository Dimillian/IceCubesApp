import AVKit
import DesignSystem
import Env
import Models
import Observation
import SwiftUI

@MainActor
@Observable public class MediaUIAttachmentVideoViewModel {
  var player: AVPlayer?
  let url: URL
  let forceAutoPlay: Bool
  var isPlaying: Bool = false

  public init(url: URL, forceAutoPlay: Bool = false) {
    self.url = url
    self.forceAutoPlay = forceAutoPlay
  }

  func preparePlayer(autoPlay: Bool, isCompact: Bool) {
    player = .init(url: url)
    player?.audiovisualBackgroundPlaybackPolicy = .pauses
    #if !os(visionOS)
      player?.preventsDisplaySleepDuringVideoPlayback = false
    #endif
    if autoPlay || forceAutoPlay, !isCompact {
      player?.play()
      isPlaying = true
    } else {
      player?.pause()
      isPlaying = false
    }
    guard let player else { return }
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem, queue: .main
    ) { _ in
      Task { @MainActor [weak self] in
        if autoPlay || self?.forceAutoPlay == true {
          self?.play()
        }
      }
    }
  }

  func mute(_ mute: Bool) {
    player?.isMuted = mute
  }

  func pause() {
    isPlaying = false
    player?.pause()
  }

  func stop() {
    isPlaying = false
    player?.pause()
    player = nil
  }

  func play() {
    isPlaying = true
    player?.seek(to: CMTime.zero)
    player?.play()
  }

  func resume() {
    isPlaying = true
    player?.play()
  }

  func preventSleep(_ preventSleep: Bool) {
    #if !os(visionOS)
      player?.preventsDisplaySleepDuringVideoPlayback = preventSleep
    #endif
  }

  deinit {
    NotificationCenter.default.removeObserver(
      self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
  }
}

@MainActor
public struct MediaUIAttachmentVideoView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.isCatalystWindow) private var isCatalystWindow
  @Environment(\.isMediaCompact) private var isCompact
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme

  @State var viewModel: MediaUIAttachmentVideoViewModel
  @State var isFullScreen: Bool = false

  public init(viewModel: MediaUIAttachmentVideoViewModel) {
    _viewModel = .init(wrappedValue: viewModel)
  }

  public var body: some View {
    videoView
      .overlay(content: {
        if isCatalystWindow {
          EmptyView()
        } else {
          HStack {}
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
              if !preferences.autoPlayVideo && !viewModel.isPlaying {
                viewModel.play()
                return
              }
              #if targetEnvironment(macCatalyst)
                viewModel.pause()
                let attachement = MediaAttachment.videoWith(url: viewModel.url)
                openWindow(
                  value: WindowDestinationMedia.mediaViewer(
                    attachments: [attachement], selectedAttachment: attachement))
              #else
                isFullScreen = true
              #endif
            }
        }
      })
      .onAppear {
        viewModel.preparePlayer(
          autoPlay: isFullScreen ? true : preferences.autoPlayVideo,
          isCompact: isCompact)
        viewModel.mute(preferences.muteVideo)
      }
      .onDisappear {
        viewModel.stop()
      }
      .fullScreenCover(isPresented: $isFullScreen) {
        modalPreview
      }
      .cornerRadius(4)
      .onChange(of: scenePhase) { _, newValue in
        switch newValue {
        case .background, .inactive:
          viewModel.pause()
        case .active:
          if (preferences.autoPlayVideo || viewModel.forceAutoPlay || isFullScreen) && !isCompact {
            viewModel.play()
          }
        default:
          break
        }
      }
  }

  private var modalPreview: some View {
    NavigationStack {
      videoView
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              isFullScreen.toggle()
            } label: {
              Image(systemName: "xmark.circle")
            }
          }
          QuickLookToolbarItem(itemUrl: viewModel.url)
        }
    }
    .onAppear {
      DispatchQueue.global().async {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
      }
      viewModel.preventSleep(true)
      viewModel.mute(false)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        if isCompact || !preferences.autoPlayVideo {
          viewModel.play()
        } else {
          viewModel.resume()
        }
      }
    }
    .onDisappear {
      if isCompact || !preferences.autoPlayVideo {
        viewModel.pause()
      }
      viewModel.preventSleep(false)
      viewModel.mute(preferences.muteVideo)
      DispatchQueue.global().async {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
      }
    }
  }

  private var videoView: some View {
    VideoPlayer(
      player: viewModel.player,
      videoOverlay: {
        if !preferences.autoPlayVideo,
          !viewModel.forceAutoPlay,
          !isFullScreen,
          !viewModel.isPlaying,
          !isCompact
        {
          Button(
            action: {
              viewModel.play()
            },
            label: {
              Image(systemName: "play.fill")
                .font(isCompact ? .body : .largeTitle)
                .foregroundColor(theme.tintColor)
                .padding(.all, isCompact ? 6 : nil)
                .background(Circle().fill(.thinMaterial))
                .padding(theme.statusDisplayStyle == .compact ? 0 : 10)
            })
        }
      }
    )
    .accessibilityAddTraits(.startsMediaSession)
    .ignoresSafeArea()
  }
}
