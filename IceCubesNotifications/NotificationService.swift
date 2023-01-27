import AppAccount
import CryptoKit
import Env
import KeychainSwift
import Models
import UIKit
import UserNotifications

@MainActor
class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    if let bestAttemptContent {
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
      bestAttemptContent.subtitle = bestAttemptContent.userInfo["i"] as? String ?? ""
      bestAttemptContent.body = notification.body.escape()
      bestAttemptContent.userInfo["plaintext"] = plaintextData
      bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "glass.caf"))

      let preferences = UserPreferences.shared
      preferences.pushNotificationsCount += 1

      bestAttemptContent.badge = .init(integerLiteral: preferences.pushNotificationsCount)

      if let urlString = notification.icon,
         let url = URL(string: urlString)
      {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("notification-attachments")
        try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        let filename = url.lastPathComponent
        let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

        Task {
          if let (data, _) = try? await URLSession.shared.data(for: .init(url: url)) {
            if let image = UIImage(data: data) {
              try? image.pngData()?.write(to: fileURL)
              if let attachment = try? UNNotificationAttachment(identifier: filename, url: fileURL, options: nil) {
                bestAttemptContent.attachments = [attachment]
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
}
