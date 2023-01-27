import Foundation
import SwiftUI

public struct ServerPreferences: Decodable {
  public let postVisibility: Visibility?
  public let postIsSensitive: Bool?
  public let postLanguage: String?
  public let autoExpandMedia: AutoExpandMedia?
  public let autoExpandSpoilers: Bool?

  public enum AutoExpandMedia: String, Decodable, CaseIterable {
    case showAll = "show_all"
    case hideAll = "hide_all"
    case hideSensitive = "default"

    public var description: LocalizedStringKey {
      switch self {
      case .showAll:
        return "enum.expand-media.show"
      case .hideAll:
        return "enum.expand-media.hide"
      case .hideSensitive:
        return "enum.expand-media.hide-sensitive"
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case postVisibility = "posting:default:visibility"
    case postIsSensitive = "posting:default:sensitive"
    case postLanguage = "posting:default:language"
    case autoExpandMedia = "reading:expand:media"
    case autoExpandSpoilers = "reading:expand:spoilers"
  }
}
