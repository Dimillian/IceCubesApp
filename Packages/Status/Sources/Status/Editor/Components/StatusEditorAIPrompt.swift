import Foundation
import Network
import SwiftUI

enum StatusEditorAIPrompt: CaseIterable {
  case correct, fit, emphasize, addTags, insertTags

  @ViewBuilder
  var label: some View {
    switch self {
    case .correct:
      Label("status.editor.ai-prompt.correct", systemImage: "text.badge.checkmark")
    case .addTags:
      Label("status.editor.ai-prompt.add-tags", systemImage: "number")
    case .insertTags:
      Label("status.editor.ai-prompt.insert-tags", systemImage: "number")
    case .fit:
      Label("status.editor.ai-prompt.fit", systemImage: "text.badge.minus")
    case .emphasize:
      Label("status.editor.ai-prompt.emphasize", systemImage: "text.badge.star")
    }
  }

  func toRequestPrompt(text: String) -> OpenAIClient.Prompt {
    switch self {
    case .correct:
      return .correct(input: text)
    case .addTags:
      return .addTags(input: text)
    case .insertTags:
      return .insertTags(input: text)
    case .fit:
      return .shorten(input: text)
    case .emphasize:
      return .emphasize(input: text)
    }
  }
}
