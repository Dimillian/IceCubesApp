import CryptoKit
import Foundation

extension NotificationService {
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

  private static func info(type: String, clientPublicKey: Data, serverPublicKey: Data) -> Data {
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
    return replacingOccurrences(of: "&amp;", with: "&")
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
