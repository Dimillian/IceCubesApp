import AVKit
import AudioToolbox
import CoreHaptics
import UIKit

@MainActor
public class SoundEffectManager {
  public static let shared: SoundEffectManager = .init()

  public enum SoundEffect: String, CaseIterable {
    case pull, refresh, tootSent, tabSelection, bookmark, boost, favorite, share
  }

  private var players: [SoundEffect: AVAudioPlayer] = [:]

  private let userPreferences = UserPreferences.shared

  private init() {
    registerSounds()
  }

  private func registerSounds() {
    SoundEffect.allCases.forEach { effect in
      guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
        let player = try? AVAudioPlayer(contentsOf: url)
      else {
        return
      }
      // Play through AVAudioPlayer so effects follow the media volume
      // instead of the (often louder) ringer volume used by
      // AudioServicesPlaySystemSound.
      player.volume = 0.7
      player.prepareToPlay()
      players[effect] = player
    }
  }

  public func playSound(_ effect: SoundEffect) {
    guard
      userPreferences.soundEffectEnabled,
      let player = players[effect]
    else {
      return
    }

    if player.isPlaying {
      player.currentTime = 0
    }
    player.play()
  }
}
