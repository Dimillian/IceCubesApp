import Foundation
import SwiftUI

public enum PreferredShareButtonBehavior: Int, CaseIterable, Codable {
  case linkOnly
  case linkAndText
  
  public var title: LocalizedStringKey {
    switch self {
    case .linkOnly: return "settings.content.sharing.share-behavior.link-only"
    case .linkAndText: return "settings.content.sharing.share-behavior.link-and-text"
    }
  }
}
