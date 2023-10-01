import CryptoKit
import KeychainSwift
import Models
import Network
import SwiftUI

public extension AppAccount {
  private static var keychain: KeychainSwift {
    let keychain = KeychainSwift()
    #if !DEBUG && !targetEnvironment(simulator)
      keychain.accessGroup = AppInfo.keychainGroup
    #endif
    return keychain
  }

  func save() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    Self.keychain.set(data, forKey: key, withAccess: .accessibleAfterFirstUnlock)
  }

  func delete() {
    Self.keychain.delete(key)
  }

  static func retrieveAll() -> [AppAccount] {
    let keychain = Self.keychain
    let decoder = JSONDecoder()
    let keys = keychain.allKeys
    var accounts: [AppAccount] = []
    for key in keys {
      if let data = keychain.getData(key) {
        if let account = try? decoder.decode(AppAccount.self, from: data) {
          accounts.append(account)
          try? account.save()
        }
      }
    }
    return accounts
  }

  static func deleteAll() {
    let keychain = Self.keychain
    let keys = keychain.allKeys
    for key in keys {
      keychain.delete(key)
    }
  }
}
