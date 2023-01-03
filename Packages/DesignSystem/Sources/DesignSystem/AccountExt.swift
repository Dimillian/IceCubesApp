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
  
  @ViewBuilder
  public var displayNameWithEmojis: some View {
    if displayName.isEmpty {
      Text(safeDisplayName)
    }
    let splittedDisplayName = displayName.split(separator: ":").map{ Part(value: $0) }
    HStack(spacing: 0) {
      if displayName.isEmpty {
        Text(" ")
      }
      ForEach(splittedDisplayName, id: \.id) { part in
        if let emoji = emojis.first(where: { $0.shortcode == part.value }) {
          LazyImage(url: emoji.url) { state in
            if let image = state.image {
              image
                .resizingMode(.aspectFit)
            } else if state.isLoading {
              ProgressView()
            } else {
              ProgressView()
            }
          }
          .processors([.resize(size: .init(width: 20, height: 20))])
          .frame(width: 20, height: 20)
        } else {
          Text(part.value)
        }
      }
    }
  }
}
