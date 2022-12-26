import Foundation
import SwiftUI
import NukeUI
import Models

@MainActor
extension Account {
  public var displayNameWithEmojis: some View {
     let splittedDisplayName = displayName.split(separator: ":")
     return HStack(spacing: 0) {
       ForEach(splittedDisplayName, id: \.self) { part in
         if let emoji = emojis.first(where: { $0.shortcode == part }) {
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
           Text(part)
         }
       }
     }
   }
}
