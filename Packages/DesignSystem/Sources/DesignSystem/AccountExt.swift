import Foundation
import Models
import NukeUI
import SwiftUI

extension Account {
  private struct Part: Identifiable {
    let id = UUID().uuidString
    let value: Substring
  }

  public var safeDisplayName: String {
    if let displayName, !displayName.isEmpty {
      return displayName
    }
    return "@\(username)"
  }

  public var displayNameWithoutEmojis: String {
    var name = safeDisplayName
    for emoji in emojis {
      name = name.replacingOccurrences(of: ":\(emoji.shortcode):", with: "")
    }
    return name.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
  }
}
