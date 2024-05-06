import Foundation
import KeychainSwift
import Models
import SwiftUI

@MainActor
public enum DeepLUserAPIHandler {
  private static let key = "DeepL"
  private static var keychain: KeychainSwift {
    let keychain = KeychainSwift()
    #if !DEBUG && !targetEnvironment(simulator)
      keychain.accessGroup = AppInfo.keychainGroup
    #endif
    return keychain
  }

  public static func write(value: String) {
    keychain.synchronizable = true
    if !value.isEmpty {
      keychain.set(value, forKey: key)
    } else {
      keychain.delete(key)
    }
  }

  public static func readIfAllowed() -> String? {
    guard UserPreferences.shared.preferredTranslationType == .useDeepl else { return nil }

    return readValue()
  }

  private static func readValue() -> String? {
    keychain.synchronizable = true
    return keychain.get(key)
  }

  public static func deactivateToggleIfNoKey() {
    if UserPreferences.shared.preferredTranslationType == .useDeepl {
      if readValue() == nil {
        UserPreferences.shared.preferredTranslationType = .useServerIfPossible
      }
    }
  }

  public static var shouldAlwaysUseDeepl: Bool {
    readIfAllowed() != nil
  }
}
