import Foundation
import NetworkClient
import SwiftUI
import FoundationModels

extension StatusEditor {
  @available(iOS 26.0, *)
  @MainActor
  public struct Assistant {
    enum Tone: String, CaseIterable {
      case professional = "Professional and formal"
      case casual = "Casual and friendly"
      case humorous = "Witty and humorous"
      case educational = "Educational and informative"
      
      @ViewBuilder
      var label: some View {
        switch self {
        case .professional:
          Label("Profesional", systemImage: "suitcase")
        case .casual:
          Label("Casual", systemImage: "face.smiling")
        case .humorous:
          Label("Humorous", systemImage: "party.popper")
        case .educational:
          Label("Educational", systemImage: "book.closed")
        }
      }
    }
    
    private static let model = SystemLanguageModel.default
        
    public static var isAvailable: Bool {
      return model.isAvailable
    }
    
    public static func prewarm() {
      session.prewarm()
    }

    @Generable
    struct Tags {
      @Guide(description: "The value of the hashtags, must be camelCased and prefixed with a # symbol.", .count(5))
      let values: [String]
    }
    
    private static let session = LanguageModelSession(model: .init(useCase: .general)) {
      """
      Your job is to assist the user in writting social media posts. 
      The users is writting for the Mastodon platforms, where posts are usually not longer than 500 characters.
      Don't return any context, only the requestesd content without quote mark.
      """
    }
    
    func generateTags(from message: String) async -> Tags {
      do {
        let response = try await Self.session.respond(to: "Generate a list of hashtags for this social media post: \(message).", generating: Tags.self)
        return response.content
      } catch {
        return .init(values: [])
      }
    }
    
    func correct(message: String) async -> LanguageModelSession.ResponseStream<String>? {
      Self.session.streamResponse(to: "Fix the spelling and grammar mistakes in the following text: \(message).",
                                              options: .init(temperature: 0.3))
    }
    
    func shorten(message: String) async -> LanguageModelSession.ResponseStream<String>? {
      Self.session.streamResponse(to: "Make a shorter version of this text: \(message).", options: .init(temperature: 0.3))
    }
    
    func emphasize(message: String) async -> LanguageModelSession.ResponseStream<String>? {
      Self.session.streamResponse(to: "Make this text catchy, more fun, be insane: \(message).", options: .init(temperature: 2.0))
    }
    
    func adjustTone(message: String, to tone: Tone) async -> LanguageModelSession.ResponseStream<String>? {
        Self.session.streamResponse(to: "Rewrite this text to be more \(tone.rawValue). Here is the message to rewrite: \(message)",
                                  options: .init(temperature: 0.8))
    }
  }
  
  @available(iOS 26.0, *)
  enum AIPrompt: CaseIterable, Hashable {
    static var allCases: [StatusEditor.AIPrompt] {
      [.rewriteWithTone(tone: .professional), .correct, .fit, .emphasize]
    }
    
    case correct, fit, emphasize, rewriteWithTone(tone: Assistant.Tone)
    
    @ViewBuilder
    var label: some View {
      switch self {
      case .correct:
        Label("status.editor.ai-prompt.correct", systemImage: "text.badge.checkmark")
      case .fit:
        Label("status.editor.ai-prompt.fit", systemImage: "text.badge.minus")
      case .emphasize:
        Label("status.editor.ai-prompt.emphasize", systemImage: "text.badge.star")
      case .rewriteWithTone:
        Label("Rewrite with tone", systemImage: "pencil.and.scribble")
      }
    }
  }
}
