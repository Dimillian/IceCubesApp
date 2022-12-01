import SwiftUI
import Timeline
import Network
import KeychainSwift
import Models

struct AppAccount: Codable {
  let server: String
  let oauthToken: OauthToken?
  
  var key: String {
    if let oauthToken {
      return "\(server):\(oauthToken.createdAt)"
    } else {
      return "\(server):anonymous:\(Date().timeIntervalSince1970)"
    }
  }
  
  func save() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    let keychain = KeychainSwift()
    keychain.set(data, forKey: key)
  }
  
  func delete() {
    KeychainSwift().delete(key)
  }
  
  static func retrieveAll() throws -> [AppAccount] {
    let keychain = KeychainSwift()
    let decoder = JSONDecoder()
    let keys = keychain.allKeys
    var accounts: [AppAccount] = []
    for key in keys {
      if let data = keychain.getData(key) {
        let account = try decoder.decode(AppAccount.self, from: data)
        accounts.append(account)
      }
    }
    return accounts
  }
  
  static func deleteAll() {
    let keychain = KeychainSwift()
    let keys = keychain.allKeys
    for key in keys {
      keychain.delete(key)
    }
  }
}
