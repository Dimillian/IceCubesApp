import Foundation
import UserNotifications
import SwiftUI
import KeychainSwift
import CryptoKit
import Models
import Network

@MainActor
public class PushNotificationsService: ObservableObject {
  enum Constants {
    static let endpoint = "https://icecubesrelay.fly.dev"
    static let keychainGroup = "346J38YKE3.com.thomasricouard.IceCubesApp"
    static let keychainAuthKey = "notifications_auth_key"
    static let keychainPrivateKey = "notifications_private_key"
  }
  
  public struct PushAccounts {
    public let server: String
    public let token: OauthToken
    
    public init(server: String, token: OauthToken) {
      self.server = server
      self.token = token
    }
  }
  
  public static let shared = PushNotificationsService()
  
  @Published public var pushToken: Data?
  
  @AppStorage("user_push_is_on") public var isUserPushEnabled: Bool = true
  @Published public var isPushEnabled: Bool = false {
    didSet {
      if !oldValue && isPushEnabled {
        requestPushNotifications()
      }
    }
  }
  @Published public var isFollowNotificationEnabled: Bool = true
  @Published public var isFavoriteNotificationEnabled: Bool = true
  @Published public var isReblogNotificationEnabled: Bool = true
  @Published public var isMentionNotificationEnabled: Bool = true
  @Published public var isPollNotificationEnabled: Bool = true
  @Published public var isNewPostsNotificationEnabled: Bool = true
  
  private var subscriptions: [PushSubscription] = []
  
  private var keychain: KeychainSwift {
    let keychain = KeychainSwift()
    #if !DEBUG
      keychain.accessGroup = Constants.keychainGroup
    #endif
    return keychain
  }
  
  public func requestPushNotifications() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
  
  public func fetchSubscriptions(accounts: [PushAccounts]) async {
    subscriptions = []
    for account in accounts {
      let client = Client(server: account.server, oauthToken: account.token)
      do {
        let sub: PushSubscription = try await client.get(endpoint: Push.subscription)
        subscriptions.append(sub)
      } catch { }
    }
    refreshSubscriptionsUI()
  }
  
  public func updateSubscriptions(accounts: [PushAccounts]) async {
    subscriptions = []
    let key = notificationsPrivateKeyAsKey.publicKey.x963Representation
    let authKey = notificationsAuthKeyAsKey
    guard let pushToken = pushToken, isUserPushEnabled else { return }
    for account in accounts {
      let client = Client(server: account.server, oauthToken: account.token)
        do {
          var listenerURL = Constants.endpoint
          listenerURL += "/push/"
          listenerURL += pushToken.hexString
          listenerURL += "/\(account.server)"
          #if DEBUG
            listenerURL += "?sandbox=true"
          #endif
          let sub: PushSubscription =
          try await client.post(endpoint: Push.createSub(endpoint: listenerURL,
                                                         p256dh: key,
                                                         auth: authKey,
                                                         mentions: isMentionNotificationEnabled,
                                                         status: isNewPostsNotificationEnabled,
                                                         reblog: isReblogNotificationEnabled,
                                                         follow: isFollowNotificationEnabled,
                                                         favourite: isFavoriteNotificationEnabled,
                                                         poll: isPollNotificationEnabled))
          subscriptions.append(sub)
        } catch { }
      }
    refreshSubscriptionsUI()
  }
  
  public func deleteSubscriptions(accounts: [PushAccounts]) async {
    for account in accounts {
      let client = Client(server: account.server, oauthToken: account.token)
      do {
        _ = try await client.delete(endpoint: Push.subscription)
      } catch { }
    }
    await fetchSubscriptions(accounts: accounts)
    refreshSubscriptionsUI()
  }
  
  private func refreshSubscriptionsUI() {
    if let sub = subscriptions.first {
      isPushEnabled = true
      isFollowNotificationEnabled = sub.alerts.follow
      isFavoriteNotificationEnabled = sub.alerts.favourite
      isReblogNotificationEnabled = sub.alerts.reblog
      isMentionNotificationEnabled = sub.alerts.mention
      isPollNotificationEnabled = sub.alerts.poll
      isNewPostsNotificationEnabled = sub.alerts.status
    } else {
      isPushEnabled = false
    }
  }
  
  // MARK: - Key management
  
  public var notificationsPrivateKeyAsKey: P256.KeyAgreement.PrivateKey {
    if let key = keychain.get(Constants.keychainPrivateKey),
       let data = Data(base64Encoded: key) {
      do {
        return try P256.KeyAgreement.PrivateKey(rawRepresentation: data)
      } catch {
        let key = P256.KeyAgreement.PrivateKey()
        keychain.set(key.rawRepresentation.base64EncodedString(),
                     forKey: Constants.keychainPrivateKey,
                     withAccess: .accessibleAfterFirstUnlock)
        return key
      }
    } else {
      let key = P256.KeyAgreement.PrivateKey()
      keychain.set(key.rawRepresentation.base64EncodedString(),
                   forKey: Constants.keychainPrivateKey,
                   withAccess: .accessibleAfterFirstUnlock)
      return key
    }
  }
  
  public var notificationsAuthKeyAsKey: Data {
    if let key = keychain.get(Constants.keychainAuthKey),
       let data = Data(base64Encoded: key) {
      return data
    } else {
      let key = Self.makeRandomeNotificationsAuthKey()
      keychain.set(key.base64EncodedString(),
                   forKey: Constants.keychainAuthKey,
                   withAccess: .accessibleAfterFirstUnlock)
      return key
    }
  }
      
  static private func makeRandomeNotificationsAuthKey() -> Data {
    let byteCount = 16
    var bytes = Data(count: byteCount)
    _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!) }
    return bytes
  }
}

extension Data {
  var hexString: String {
    return map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
  }
}

