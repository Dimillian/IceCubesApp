import Foundation

public struct InstanceApp: Codable, Identifiable {
  public var id = ""
  public var name = ""
  public var website: URL?
  public var redirectUri = ""
  public var clientId = ""
  public var clientSecret = ""
  public var vapidKey = ""
  
  enum CodingKeys: String, CodingKey {
    case id, name, website, redirectUri, clientId, clientSecret, vapidKey
  }

  public init(from decoder: Decoder) throws {
    do {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      if let txt = try? values.decode(String.self, forKey: .id) {
        id = txt
      }
      name = try values.decode(String.self, forKey: .name)
      website = try values.decode(URL.self, forKey: .website)
      redirectUri = try values.decode(String.self, forKey: .redirectUri)
      clientId = try values.decode(String.self, forKey: .clientId)
      clientSecret = try values.decode(String.self, forKey: .clientSecret)
      vapidKey = try values.decode(String.self, forKey: .vapidKey)
    } catch {
      NSLog("*** Error decoding InstanceApp: \(error)")
      throw error
    }
  }
}
