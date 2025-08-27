import Combine
import CryptoKit
import Foundation
import KeychainSwift
import Models
import NetworkClient
import Observation
import SwiftUI
import UserNotifications

extension UNNotification: @unchecked @retroactive Sendable {}
extension UNNotificationResponse: @unchecked @retroactive Sendable {}
extension UNUserNotificationCenter: @unchecked @retroactive Sendable {}

public struct PushKeys: Sendable {
  enum Constants {
    static let keychainAuthKey = "notifications_auth_key"
    static let keychainPrivateKey = "notifications_private_key"
  }

  public init() {}

  private var keychain: KeychainSwift {
    let keychain = KeychainSwift()
    #if !DEBUG && !targetEnvironment(simulator)
      keychain.accessGroup = AppInfo.keychainGroup
    #endif
    return keychain
  }

  public var notificationsPrivateKeyAsKey: P256.KeyAgreement.PrivateKey {
    if let key = keychain.get(Constants.keychainPrivateKey),
      let data = Data(base64Encoded: key)
    {
      do {
        return try P256.KeyAgreement.PrivateKey(rawRepresentation: data)
      } catch {
        let key = P256.KeyAgreement.PrivateKey()
        keychain.set(
          key.rawRepresentation.base64EncodedString(),
          forKey: Constants.keychainPrivateKey,
          withAccess: .accessibleAfterFirstUnlock)
        return key
      }
    } else {
      let key = P256.KeyAgreement.PrivateKey()
      keychain.set(
        key.rawRepresentation.base64EncodedString(),
        forKey: Constants.keychainPrivateKey,
        withAccess: .accessibleAfterFirstUnlock)
      return key
    }
  }

  public var notificationsAuthKeyAsKey: Data {
    if let key = keychain.get(Constants.keychainAuthKey),
      let data = Data(base64Encoded: key)
    {
      return data
    } else {
      let key = Self.makeRandomNotificationsAuthKey()
      keychain.set(
        key.base64EncodedString(),
        forKey: Constants.keychainAuthKey,
        withAccess: .accessibleAfterFirstUnlock)
      return key
    }
  }

  private static func makeRandomNotificationsAuthKey() -> Data {
    let byteCount = 16
    var bytes = Data(count: byteCount)
    _ = bytes.withUnsafeMutableBytes {
      SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!)
    }
    return bytes
  }
}

public struct PushAccount: Equatable {
  public let server: String
  public let token: OauthToken
  public let accountName: String?

  public init(server: String, token: OauthToken, accountName: String?) {
    self.server = server
    self.token = token
    self.accountName = accountName
  }
}

public struct HandledNotification: Equatable {
  public let account: PushAccount
  public let notification: Models.Notification
}

@MainActor
@Observable public class PushNotificationsService: NSObject {
  enum Constants {
    static let endpoint = "https://icecubesrelay.fly.dev"
  }

  public static let shared = PushNotificationsService()

  private let pushKeys = PushKeys()

  public private(set) var subscriptions: [PushNotificationSubscriptionSettings] = []

  public var pushToken: Data?

  public var handledNotification: HandledNotification?

  override init() {
    super.init()

    UNUserNotificationCenter.current().delegate = self
  }

  public func requestPushNotifications() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      @Sendable _, _ in
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  public func setAccounts(accounts: [PushAccount]) {
    subscriptions = []
    for account in accounts {
      let sub = PushNotificationSubscriptionSettings(
        account: account,
        key: pushKeys.notificationsPrivateKeyAsKey.publicKey.x963Representation,
        authKey: pushKeys.notificationsAuthKeyAsKey,
        pushToken: pushToken)
      subscriptions.append(sub)
    }
  }

  public func updateSubscriptions(forceCreate: Bool) async {
    for subscription in subscriptions {
      await withTaskGroup(
        of: Void.self,
        body: { group in
          group.addTask {
            await subscription.fetchSubscription()
            if await subscription.subscription != nil, !forceCreate {
              await subscription.deleteSubscription()
              await subscription.updateSubscription()
            } else if forceCreate {
              await subscription.updateSubscription()
            }
          }
        })
    }
  }
}

extension PushNotificationsService: UNUserNotificationCenterDelegate {
  public func userNotificationCenter(
    _: UNUserNotificationCenter, didReceive response: UNNotificationResponse
  ) async {
    guard let plaintext = response.notification.request.content.userInfo["plaintext"] as? Data,
      let mastodonPushNotification = try? JSONDecoder().decode(
        MastodonPushNotification.self, from: plaintext),
      let account = subscriptions.first(where: {
        $0.account.token.accessToken == mastodonPushNotification.accessToken
      })
    else {
      return
    }
    do {
      let client = MastodonClient(server: account.account.server, oauthToken: account.account.token)
      let notification: Models.Notification =
        try await client.get(
          endpoint: Notifications.notification(id: String(mastodonPushNotification.notificationID)))
      handledNotification = .init(account: account.account, notification: notification)
    } catch {}
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    return [.banner, .sound]
  }
}

extension Data {
  var hexString: String {
    map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
  }
}

@MainActor
@Observable public class PushNotificationSubscriptionSettings {
  public var isEnabled: Bool = true
  public var isFollowNotificationEnabled: Bool = true
  public var isFavoriteNotificationEnabled: Bool = true
  public var isReblogNotificationEnabled: Bool = true
  public var isMentionNotificationEnabled: Bool = true
  public var isPollNotificationEnabled: Bool = true
  public var isNewPostsNotificationEnabled: Bool = true

  public let account: PushAccount

  private let key: Data
  private let authKey: Data

  public var pushToken: Data?

  public private(set) var subscription: PushSubscription?

  public init(account: PushAccount, key: Data, authKey: Data, pushToken: Data?) {
    self.account = account
    self.key = key
    self.authKey = authKey
    self.pushToken = pushToken
  }

  private func refreshSubscriptionsUI() {
    if let subscription {
      isFollowNotificationEnabled = subscription.alerts.follow
      isFavoriteNotificationEnabled = subscription.alerts.favourite
      isReblogNotificationEnabled = subscription.alerts.reblog
      isMentionNotificationEnabled = subscription.alerts.mention
      isPollNotificationEnabled = subscription.alerts.poll
      isNewPostsNotificationEnabled = subscription.alerts.status
    }
  }

  public func updateSubscription() async {
    guard let pushToken else { return }
    let client = MastodonClient(server: account.server, oauthToken: account.token)
    do {
      var listenerURL = PushNotificationsService.Constants.endpoint
      listenerURL += "/push/"
      listenerURL += pushToken.hexString
      listenerURL += "/\(account.accountName ?? account.server)"
      #if DEBUG
        listenerURL += "?sandbox=true"
      #endif
      subscription =
        try await client.post(
          endpoint: Push.createSub(
            endpoint: listenerURL,
            p256dh: key,
            auth: authKey,
            mentions: isMentionNotificationEnabled,
            status: isNewPostsNotificationEnabled,
            reblog: isReblogNotificationEnabled,
            follow: isFollowNotificationEnabled,
            favorite: isFavoriteNotificationEnabled,
            poll: isPollNotificationEnabled))
      isEnabled = subscription != nil

    } catch {
      isEnabled = false
    }
    refreshSubscriptionsUI()
  }

  public func deleteSubscription() async {
    let client = MastodonClient(server: account.server, oauthToken: account.token)
    do {
      _ = try await client.delete(endpoint: Push.subscription)
      subscription = nil
      await fetchSubscription()
      refreshSubscriptionsUI()
      while subscription != nil {
        await deleteSubscription()
      }
      isEnabled = false
    } catch {}
  }

  public func fetchSubscription() async {
    let client = MastodonClient(server: account.server, oauthToken: account.token)
    do {
      subscription = try await client.get(endpoint: Push.subscription)
      isEnabled = subscription != nil
    } catch {
      subscription = nil
      isEnabled = false
    }
    refreshSubscriptionsUI()
  }
}
