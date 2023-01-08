import UserNotifications
import KeychainSwift
import Env
import CryptoKit
import Models

@MainActor
class NotificationService: UNNotificationServiceExtension {
  
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?
  
  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    bestAttemptContent?.title = "A new notification have been received"
    
    if let bestAttemptContent {
      let privateKey = PushNotifications.shared.notificationsPrivateKeyAsKey
      let auth = PushNotifications.shared.notificationsAuthKeyAsKey
      
      guard let encodedPayload = bestAttemptContent.userInfo["m"] as? String,
            let payload = Data(base64Encoded: encodedPayload.URLSafeBase64ToBase64()) else {
        contentHandler(bestAttemptContent)
        return
      }
  
      guard let encodedPublicKey = bestAttemptContent.userInfo["k"] as? String,
            let publicKeyData = Data(base64Encoded: encodedPublicKey.URLSafeBase64ToBase64()),
            let publicKey = try? P256.KeyAgreement.PublicKey(x963Representation: publicKeyData) else {
        contentHandler(bestAttemptContent)
        return
      }
      
      guard let encodedSalt = bestAttemptContent.userInfo["s"] as? String,
            let salt = Data(base64Encoded: encodedSalt.URLSafeBase64ToBase64()) else {
        contentHandler(bestAttemptContent)
        return
      }
      
      guard let plaintextData = NotificationService.decrypt(payload: payload,
                                                            salt: salt,
                                                            auth: auth,
                                                            privateKey: privateKey,
                                                            publicKey: publicKey),
            let notification = try? JSONDecoder().decode(MastodonPushNotification.self, from: plaintextData) else {
        contentHandler(bestAttemptContent)
        return
      }
      
      bestAttemptContent.title = notification.title
      bestAttemptContent.subtitle = ""
      bestAttemptContent.body = notification.body.escape()
      bestAttemptContent.userInfo["plaintext"] = plaintextData
      
      contentHandler(bestAttemptContent)
    }
  }
  
  static func decrypt(payload: Data, salt: Data, auth: Data, privateKey: P256.KeyAgreement.PrivateKey, publicKey: P256.KeyAgreement.PublicKey) -> Data? {
    guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: publicKey) else {
      return nil
    }
    
    let keyMaterial = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: auth, sharedInfo: Data("Content-Encoding: auth\0".utf8), outputByteCount: 32)
    
    let keyInfo = info(type: "aesgcm", clientPublicKey: privateKey.publicKey.x963Representation, serverPublicKey: publicKey.x963Representation)
    let key = HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: keyInfo, outputByteCount: 16)
    
    let nonceInfo = info(type: "nonce", clientPublicKey: privateKey.publicKey.x963Representation, serverPublicKey: publicKey.x963Representation)
    let nonce = HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: nonceInfo, outputByteCount: 12)
    
    let nonceData = nonce.withUnsafeBytes(Array.init)
    
    guard let sealedBox = try? AES.GCM.SealedBox(combined: nonceData + payload) else {
      return nil
    }
    
    var _plaintext: Data?
    do {
      _plaintext = try AES.GCM.open(sealedBox, using: key)
    } catch {
      print(error)
    }
    guard let plaintext = _plaintext else {
      return nil
    }
    
    let paddingLength = Int(plaintext[0]) * 256 + Int(plaintext[1])
    guard plaintext.count >= 2 + paddingLength else {
      print("1")
      fatalError()
    }
    let unpadded = plaintext.suffix(from: paddingLength + 2)
    
    return Data(unpadded)
  }
  
  static private func info(type: String, clientPublicKey: Data, serverPublicKey: Data) -> Data {
    var info = Data()
    
    info.append("Content-Encoding: ".data(using: .utf8)!)
    info.append(type.data(using: .utf8)!)
    info.append(0)
    info.append("P-256".data(using: .utf8)!)
    info.append(0)
    info.append(0)
    info.append(65)
    info.append(clientPublicKey)
    info.append(0)
    info.append(65)
    info.append(serverPublicKey)
    
    return info
  }
}

extension String {
  func escape() -> String {
    return self
      .replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&apos;", with: "'")
      .replacingOccurrences(of: "&#39;", with: "’")
    
  }
  
  func URLSafeBase64ToBase64() -> String {
    var base64 = replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let countMod4 = count % 4
    
    if countMod4 != 0 {
      base64.append(String(repeating: "=", count: 4 - countMod4))
    }
    
    return base64
  }
}

