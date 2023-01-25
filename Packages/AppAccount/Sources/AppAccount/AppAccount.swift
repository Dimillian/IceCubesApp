import CryptoKit
import KeychainSwift
import Models
import Network
import SwiftUI

extension AppAccount {
  private static var keychain: KeychainSwift {
    let keychain = KeychainSwift()
    #if !DEBUG
      keychain.accessGroup = AppInfo.keychainGroup
    #endif
    return keychain
  }

  public func save() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    Self.keychain.set(data, forKey: key)
  }

  public func delete() {
    Self.keychain.delete(key)
  }

  public static func retrieveAll() -> [AppAccount] {
    migrateLegacyAccounts()
    let keychain = Self.keychain
    let decoder = JSONDecoder()
    let keys = keychain.allKeys
    var accounts: [AppAccount] = []
    for key in keys {
      if let data = keychain.getData(key) {
        if let account = try? decoder.decode(AppAccount.self, from: data) {
          accounts.append(account)
        }
      }
    }
    return accounts
  }

  public static func migrateLegacyAccounts() {
    let keychain = KeychainSwift()
    let decoder = JSONDecoder()
    let keys = keychain.allKeys
    for key in keys {
      if let data = keychain.getData(key) {
        if let account = try? decoder.decode(AppAccount.self, from: data) {
          try? account.save()
        }
      }
    }
  }

  public static func deleteAll() {
    let keychain = Self.keychain
    let keys = keychain.allKeys
    for key in keys {
      keychain.delete(key)
    }
  }
}
