import AppAccount
import CryptoKit
import Env
import Intents
import KeychainSwift
import Models
import NetworkClient
import Notifications
import UIKit
import UserNotifications

extension UNMutableNotificationContent: @unchecked @retroactive Sendable {}

class NotificationService: UNNotificationServiceExtension {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {

    let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
    let provider = NotificationServiceContentProvider(bestAttemptContent: bestAttemptContent)
    let casted = unsafeBitCast(
      contentHandler,
      to: (@Sendable (UNNotificationContent) -> Void).self)
    Task {
      if let content = await provider.buildContent() {
        casted(content)
      }
    }
  }
}

actor NotificationServiceContentProvider {
  var bestAttemptContent: UNMutableNotificationContent?

  private let pushKeys = PushKeys()
  private let keychainAccounts = AppAccount.retrieveAll()

  init(bestAttemptContent: UNMutableNotificationContent? = nil) {
    self.bestAttemptContent = bestAttemptContent
  }

  func buildContent() async -> UNMutableNotificationContent? {
    if var bestAttemptContent {
      let privateKey = pushKeys.notificationsPrivateKeyAsKey
      let auth = pushKeys.notificationsAuthKeyAsKey

      guard let encodedPayload = bestAttemptContent.userInfo["m"] as? String,
        let payload = Data(base64Encoded: encodedPayload.URLSafeBase64ToBase64())
      else {
        return bestAttemptContent
      }

      guard let encodedPublicKey = bestAttemptContent.userInfo["k"] as? String,
        let publicKeyData = Data(base64Encoded: encodedPublicKey.URLSafeBase64ToBase64()),
        let publicKey = try? P256.KeyAgreement.PublicKey(x963Representation: publicKeyData)
      else {
        return bestAttemptContent
      }

      guard let encodedSalt = bestAttemptContent.userInfo["s"] as? String,
        let salt = Data(base64Encoded: encodedSalt.URLSafeBase64ToBase64())
      else {
        return bestAttemptContent
      }

      guard
        let plaintextData = NotificationService.decrypt(
          payload: payload,
          salt: salt,
          auth: auth,
          privateKey: privateKey,
          publicKey: publicKey),
        let notification = try? JSONDecoder().decode(
          MastodonPushNotification.self, from: plaintextData)
      else {
        return bestAttemptContent
      }

      bestAttemptContent.title = notification.title
      if keychainAccounts.count > 1 {
        bestAttemptContent.subtitle = bestAttemptContent.userInfo["i"] as? String ?? ""
      }
      bestAttemptContent.body = notification.body.escape()
      bestAttemptContent.userInfo["plaintext"] = plaintextData
      bestAttemptContent.sound = UNNotificationSound(
        named: UNNotificationSoundName(rawValue: "glass.caf"))
      let badgeCount = await updateBadgeCoung(notification: notification)
      bestAttemptContent.badge = .init(integerLiteral: badgeCount)

      if let urlString = notification.icon,
        let url = URL(string: urlString)
      {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent("notification-attachments")
        try? FileManager.default.createDirectory(
          at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        let filename = url.lastPathComponent
        let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

        // Warning: Non-sendable type '(any URLSessionTaskDelegate)?' exiting main actor-isolated
        // context in call to non-isolated instance method 'data(for:delegate:)' cannot cross actor
        // boundary.
        // This is on the defaulted-to-nil second parameter of `.data(from:delegate:)`.
        // There is a Radar tracking this & others like it.
        if let (data, _) = try? await URLSession.shared.data(for: .init(url: url)) {
          if let image = UIImage(data: data) {
            try? image.pngData()?.write(to: fileURL)

            if let remoteNotification = await toRemoteNotification(localNotification: notification),
              let type = remoteNotification.supportedType
            {
              let intent = buildMessageIntent(
                remoteNotification: remoteNotification,
                currentUser: bestAttemptContent.userInfo["i"] as? String ?? "",
                avatarURL: fileURL)
              do {
                bestAttemptContent =
                  try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
                bestAttemptContent.threadIdentifier = remoteNotification.type
                if type == .mention {
                  bestAttemptContent.body = notification.body.escape()
                } else {
                  let newBody =
                    "\(NSLocalizedString(type.notificationKey(), bundle: .main, comment: ""))\(notification.body.escape())"
                  bestAttemptContent.body = newBody
                }
                return bestAttemptContent
              } catch {
                return bestAttemptContent
              }
            } else {
              if let attachment = try? UNNotificationAttachment(
                identifier: filename,
                url: fileURL,
                options: nil)
              {
                bestAttemptContent.attachments = [attachment]
              }
            }
          }
        } else {
          return bestAttemptContent
        }
      } else {
        return bestAttemptContent
      }
    }
    return nil
  }

  private func toRemoteNotification(localNotification: MastodonPushNotification) async -> Models
    .Notification?
  {
    do {
      if let account = keychainAccounts.first(where: {
        $0.oauthToken?.accessToken == localNotification.accessToken
      }) {
        let client = MastodonClient(server: account.server, oauthToken: account.oauthToken)
        let remoteNotification: Models.Notification = try await client.get(
          endpoint: Notifications.notification(id: String(localNotification.notificationID)))
        return remoteNotification
      }
    } catch {
      return nil
    }
    return nil
  }

  private func buildMessageIntent(
    remoteNotification: Models.Notification,
    currentUser: String,
    avatarURL: URL
  ) -> INSendMessageIntent {
    let handle = INPersonHandle(value: remoteNotification.account.id, type: .unknown)
    let avatar = INImage(url: avatarURL)
    let sender = INPerson(
      personHandle: handle,
      nameComponents: nil,
      displayName: remoteNotification.account.safeDisplayName,
      image: avatar,
      contactIdentifier: nil,
      customIdentifier: nil)
    var recipents: [INPerson]?
    var groupName: INSpeakableString?
    if keychainAccounts.count > 1 {
      let me = INPerson(
        personHandle: .init(value: currentUser, type: .unknown),
        nameComponents: nil,
        displayName: currentUser,
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil)
      recipents = [me, sender]
      groupName = .init(spokenPhrase: currentUser)
    }
    let intent = INSendMessageIntent(
      recipients: recipents,
      outgoingMessageType: .outgoingMessageText,
      content: nil,
      speakableGroupName: groupName,
      conversationIdentifier: remoteNotification.account.id,
      serviceName: nil,
      sender: sender,
      attachments: nil)
    if groupName != nil {
      intent.setImage(avatar, forParameterNamed: \.speakableGroupName)
    }
    return intent
  }

  @MainActor
  private func updateBadgeCoung(notification: MastodonPushNotification) -> Int {
    let preferences = UserPreferences.shared
    let tokens = AppAccountsManager.shared.pushAccounts.map(\.token)
    preferences.reloadNotificationsCount(tokens: tokens)

    if let token = keychainAccounts.first(where: {
      $0.oauthToken?.accessToken == notification.accessToken
    })?.oauthToken {
      var currentCount = preferences.notificationsCount[token] ?? 0
      currentCount += 1
      preferences.notificationsCount[token] = currentCount
    }
    return preferences.totalNotificationsCount
  }
}
