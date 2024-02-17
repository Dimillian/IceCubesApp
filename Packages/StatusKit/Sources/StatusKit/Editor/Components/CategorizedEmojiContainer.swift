import Foundation
import Models

extension StatusEditor {
  struct CategorizedEmojiContainer: Identifiable, Equatable {
    let id = UUID().uuidString
    let categoryName: String
    var emojis: [Emoji]
  }
}
