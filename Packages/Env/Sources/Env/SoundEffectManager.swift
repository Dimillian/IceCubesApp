import AVKit
import CoreHaptics
import UIKit
import AudioToolbox

@MainActor
public class SoundEffectManager {
  public static let shared: SoundEffectManager = .init()
  
  public enum SoundEffect: String, CaseIterable {
    case pull, refresh, tootSent, tabSelection, bookmark, boost, favorite, share
  }
  
  var pullId: SystemSoundID = 0
  var refreshId: SystemSoundID = 1
  var tootSentId: SystemSoundID = 2
  var tabSelectionId: SystemSoundID = 3
  var bookmarkId: SystemSoundID = 4
  var boostId: SystemSoundID = 5
  var favoriteId: SystemSoundID = 6
  var shareId: SystemSoundID = 7
  
  private let userPreferences = UserPreferences.shared
  
  private init() {
    registerSounds()
  }

  private func registerSounds() {
    for effect in SoundEffect.allCases {
      if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") {
        switch effect {
        case .pull:
          AudioServicesCreateSystemSoundID(url as CFURL, &pullId)
        case .refresh:
          AudioServicesCreateSystemSoundID(url as CFURL, &refreshId)
        case .tootSent:
          AudioServicesCreateSystemSoundID(url as CFURL, &tootSentId)
        case .tabSelection:
          AudioServicesCreateSystemSoundID(url as CFURL, &tabSelectionId)
        case .bookmark:
          AudioServicesCreateSystemSoundID(url as CFURL, &bookmarkId)
        case .boost:
          AudioServicesCreateSystemSoundID(url as CFURL, &boostId)
        case .favorite:
          AudioServicesCreateSystemSoundID(url as CFURL, &favoriteId)
        case .share:
          AudioServicesCreateSystemSoundID(url as CFURL, &shareId)
        }
      }
    }
  }
  
  public func playSound(of type: SoundEffect) {
    guard userPreferences.soundEffectEnabled else { return }
    switch type {
    case .pull:
      AudioServicesPlaySystemSound(pullId)
    case .refresh:
      AudioServicesPlaySystemSound(refreshId)
    case .tootSent:
      AudioServicesPlaySystemSound(tootSentId)
    case .tabSelection:
      AudioServicesPlaySystemSound(tabSelectionId)
    case .bookmark:
      AudioServicesPlaySystemSound(bookmarkId)
    case .boost:
      AudioServicesPlaySystemSound(boostId)
    case .favorite:
      AudioServicesPlaySystemSound(favoriteId)
    case .share:
      AudioServicesPlaySystemSound(shareId)
    }
  }
}
