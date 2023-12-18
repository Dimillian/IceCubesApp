import Foundation
import Models

struct StatusEditorCategorizedEmojiContainer: Identifiable, Equatable {
  let id = UUID().uuidString
  let categoryName: String
  var emojis: [Emoji]
}
