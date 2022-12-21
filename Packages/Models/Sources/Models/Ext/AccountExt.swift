import Foundation
import SwiftUI

extension Account {
  public var displayNameWithEmojis: some View {
    let splittedDisplayName = displayName.split(separator: ":")
    return HStack(spacing: 0) {
      ForEach(splittedDisplayName, id: \.self) { part in
        if let emoji = emojis.first(where: { $0.shortcode == part }) {
          AsyncImage(
            url: emoji.url,
            content: { image in
              image.resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 20, maxHeight: 20)
            },
            placeholder: {
              ProgressView()
            }
          )
        } else {
          Text(part)
        }
      }
    }
  }
}
