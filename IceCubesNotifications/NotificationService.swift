import AppAccount
import CryptoKit
import Env
@preconcurrency import Intents
import KeychainSwift
import Models
import Network
import Notifications
import UIKit
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  @MainActor override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    if var bestAttemptContent {
      let privateKey = PushNotificationsService.shared.notificationsPrivateKeyAsKey
      let auth = PushNotificationsService.shared.notificationsAuthKeyAsKey

      guard let encodedPayload = bestAttemptContent.userInfo["m"] as? String,
            let payload = Data(base64Encoded: encodedPayload.URLSafeBase64ToBase64())
      else {
        contentHandler(bestAttemptContent)
        return
      }

      guard let encodedPublicKey = bestAttemptContent.userInfo["k"] as? String,
            let publicKeyData = Data(base64Encoded: encodedPublicKey.URLSafeBase64ToBase64()),
            let publicKey = try? P256.KeyAgreement.PublicKey(x963Representation: publicKeyData)
      else {
        contentHandler(bestAttemptContent)
        return
      }

      guard let encodedSalt = bestAttemptContent.userInfo["s"] as? String,
            let salt = Data(base64Encoded: encodedSalt.URLSafeBase64ToBase64())
      else {
        contentHandler(bestAttemptContent)
        return
      }

      guard let plaintextData = NotificationService.decrypt(payload: payload,
                                                            salt: salt,
                                                            auth: auth,
                                                            privateKey: privateKey,
                                                            publicKey: publicKey),
        let notification = try? JSONDecoder().decode(MastodonPushNotification.self, from: plaintextData)
      else {
        contentHandler(bestAttemptContent)
        return
      }

      bestAttemptContent.title = notification.title
      if AppAccountsManager.shared.availableAccounts.count > 1 {
        bestAttemptContent.subtitle = bestAttemptContent.userInfo["i"] as? String ?? ""
      }
      bestAttemptContent.body = notification.body.escape()
      bestAttemptContent.userInfo["plaintext"] = plaintextData
      bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "glass.caf"))

      let preferences = UserPreferences.shared
      let tokens = AppAccountsManager.shared.pushAccounts.map(\.token)
      preferences.reloadNotificationsCount(tokens: tokens)

      if let token = AppAccountsManager.shared.availableAccounts.first(where: { $0.oauthToken?.accessToken == notification.accessToken })?.oauthToken {
        var currentCount = preferences.notificationsCount[token] ?? 0
        currentCount += 1
        preferences.notificationsCount[token] = currentCount
      }

      bestAttemptContent.badge = .init(integerLiteral: preferences.totalNotificationsCount)

      if let urlString = notification.icon,
         let url = URL(string: urlString)
      {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("notification-attachments")
        try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        let filename = url.lastPathComponent
        let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

        Task {
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
                let intent = buildMessageIntent(remoteNotification: remoteNotification,
                                                currentUser: bestAttemptContent.userInfo["i"] as? String ?? "",
                                                avatarURL: fileURL)
                bestAttemptContent = try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
                bestAttemptContent.threadIdentifier = remoteNotification.type
                if type == .mention {
                  bestAttemptContent.body = notification.body.escape()
                } else {
                  let newBody = "\(NSLocalizedString(type.notificationKey(), bundle: .main, comment: ""))\(notification.body.escape())"
                  bestAttemptContent.body = newBody
                }
              } else {
                if let attachment = try? UNNotificationAttachment(identifier: filename, url: fileURL, options: nil) {
                  bestAttemptContent.attachments = [attachment]
                }
              }
            }
            contentHandler(bestAttemptContent)
          } else {
            contentHandler(bestAttemptContent)
          }
        }
      } else {
        contentHandler(bestAttemptContent)
      }
    }
  }

  @MainActor
  private func toRemoteNotification(localNotification: MastodonPushNotification) async -> Models.Notification? {
    do {
      if let account = AppAccountsManager.shared.availableAccounts.first(where: { $0.oauthToken?.accessToken == localNotification.accessToken }) {
        let client = Client(server: account.server, oauthToken: account.oauthToken)
        let remoteNotification: Models.Notification = try await client.get(endpoint: Notifications.notification(id: String(localNotification.notificationID)))
        return remoteNotification
      }
    } catch {
      return nil
    }
    return nil
  }

  @MainActor
  private func buildMessageIntent(remoteNotification: Models.Notification,
                                  currentUser: String,
                                  avatarURL: URL) -> INSendMessageIntent
  {
    let handle = INPersonHandle(value: remoteNotification.account.id, type: .unknown)
    let avatar = INImage(url: avatarURL)
    let sender = INPerson(personHandle: handle,
                          nameComponents: nil,
                          displayName: remoteNotification.account.safeDisplayName,
                          image: avatar,
                          contactIdentifier: nil,
                          customIdentifier: nil)
    var recipents: [INPerson]?
    var groupName: INSpeakableString?
    if AppAccountsManager.shared.availableAccounts.count > 1 {
      let me = INPerson(personHandle: .init(value: currentUser, type: .unknown),
                        nameComponents: nil,
                        displayName: currentUser,
                        image: nil,
                        contactIdentifier: nil,
                        customIdentifier: nil)
      recipents = [me, sender]
      groupName = .init(spokenPhrase: currentUser)
    }
    let intent = INSendMessageIntent(recipients: recipents,
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
}
