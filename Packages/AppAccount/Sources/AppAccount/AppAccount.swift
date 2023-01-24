import CryptoKit
import KeychainSwift
import Models
import Network
import SwiftUI

public struct AppAccount: Codable, Identifiable {
  public let server: String
  public var accountName: String?
  public let oauthToken: OauthToken?

  public var id: String {
    key
  }

  private static var keychain: KeychainSwift {
    let keychain = KeychainSwift()
    #if !DEBUG
      keychain.accessGroup = AppInfo.keychainGroup
    #endif
    return keychain
  }

  public var key: String {
    if let oauthToken {
      return "\(server):\(oauthToken.createdAt)"
    } else {
      return "\(server):anonymous:\(Date().timeIntervalSince1970)"
    }
  }

  public init(server: String,
              accountName: String?,
              oauthToken: OauthToken? = nil) {
    self.server = server
    self.accountName = accountName
    self.oauthToken = oauthToken
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
