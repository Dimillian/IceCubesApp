import AudioToolbox
import AVKit
import CoreHaptics
import UIKit

@MainActor
public class SoundEffectManager {
  public static let shared: SoundEffectManager = .init()

  public enum SoundEffect: String, CaseIterable {
    case pull, refresh, tootSent, tabSelection, bookmark, boost, favorite, share
  }

  private var systemSoundIDs: [SoundEffect: SystemSoundID] = [:]

  private let userPreferences = UserPreferences.shared

  private init() {
    registerSounds()
  }

  private func registerSounds() {
    SoundEffect.allCases.forEach { effect in
      guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else { return }
      register(url: url, for: effect)
    }
  }

  private func register(url: URL, for effect: SoundEffect) {
    var soundId: SystemSoundID = .init()
    AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
    systemSoundIDs[effect] = soundId
  }

  public func playSound(_ effect: SoundEffect) {
    guard
      userPreferences.soundEffectEnabled,
      let soundId = systemSoundIDs[effect]
    else {
      return
    }

    AudioServicesPlaySystemSound(soundId)
  }
}
