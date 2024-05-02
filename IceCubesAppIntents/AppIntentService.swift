import SwiftUI
import AppIntents

@Observable
public class AppIntentService: @unchecked Sendable {
  struct HandledIntent: Equatable {
    static func == (lhs: AppIntentService.HandledIntent, rhs: AppIntentService.HandledIntent) -> Bool {
      lhs.id == rhs.id
    }
    
    let id: String
    let intent: any AppIntent
    
    init(intent: any AppIntent) {
      self.id = UUID().uuidString
      self.intent = intent
    }
  }
  
  public static let shared = AppIntentService()
  
  var handledIntent: HandledIntent?
  
  private init() { }
}
