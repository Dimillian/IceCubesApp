import Foundation
import SwiftUI
import NukeUI
import Models

extension Account {
  private struct Part: Identifiable {
    let id = UUID().uuidString
    let value: Substring
  }
  
  public var safeDisplayName: String {
    if displayName.isEmpty {
      return username
    }
    return displayName
  }
    
  public var displayNameWithoutEmojis: String {
    var name = safeDisplayName
    for emoji in emojis {
      name = name.replacingOccurrences(of: ":\(emoji.shortcode):", with: "")
    }
    return name.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
  }
}
