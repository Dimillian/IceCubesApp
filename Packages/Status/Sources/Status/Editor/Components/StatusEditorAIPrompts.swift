import Foundation
import Network
import SwiftUI

enum StatusEditorAIPrompts: CaseIterable {
  case correct, fit, emphasize

  @ViewBuilder
  var label: some View {
    switch self {
    case .correct:
      Label("Correct text", systemImage: "text.badge.checkmark")
    case .fit:
      Label("Shorten text", systemImage: "text.badge.minus")
    case .emphasize:
      Label("Emphasize text", systemImage: "text.badge.star")
    }
  }

  func toRequestPrompt(text: String) -> OpenAIClient.Prompts {
    switch self {
    case .correct:
      return .correct(input: text)
    case .fit:
      return .shorten(input: text)
    case .emphasize:
      return .emphasize(input: text)
    }
  }
}
