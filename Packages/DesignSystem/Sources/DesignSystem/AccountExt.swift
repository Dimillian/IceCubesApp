import Foundation
import SwiftUI
import NukeUI
import Models

@MainActor
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
}
