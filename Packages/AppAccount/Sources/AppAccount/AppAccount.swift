import SwiftUI
import Network
import KeychainSwift
import Models
import CryptoKit

public struct AppAccount: Codable, Identifiable {
  public let server: String
  public let oauthToken: OauthToken?
  
  public var id: String {
    key
  }
  
  public var key: String {
    if let oauthToken {
      return "\(server):\(oauthToken.createdAt)"
    } else {
      return "\(server):anonymous:\(Date().timeIntervalSince1970)"
    }
  }
  
  public init(server: String, oauthToken: OauthToken? = nil) {
    self.server = server
    self.oauthToken = oauthToken
  }
  
  public func save() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    let keychain = KeychainSwift()
    keychain.set(data, forKey: key)
  }
  
  public func delete() {
    KeychainSwift().delete(key)
  }
  
  public static func retrieveAll() -> [AppAccount] {
    let keychain = KeychainSwift()
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
  
  public static func deleteAll() {
    let keychain = KeychainSwift()
    let keys = keychain.allKeys
    for key in keys {
      keychain.delete(key)
    }
  }
}
