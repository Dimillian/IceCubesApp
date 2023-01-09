import Foundation

public struct ServerPreferences: Decodable {
  public let postVisibility: Visibility?
  public let postIsSensitive: Bool?
  public let postLanguage: String?
  public let autoExpandmedia: AutoExpandMedia?
  public let autoExpandSpoilers: Bool?
  
  public enum AutoExpandMedia: String, Decodable {
    case showAll = "show_all"
    case hideAll = "hide_all"
    case hideSensitive = "default"
  }
  
  enum CodingKeys: String, CodingKey {
    case postVisibility = "posting:default:visibility"
    case postIsSensitive = "posting:default:sensitive"
    case postLanguage = "posting:default:language"
    case autoExpandmedia = "reading:expand:media"
    case autoExpandSpoilers = "reading:expand:spoilers"
  }
}
