import Foundation

@Observable
@MainActor
public class TipedUsers {
  public var usersIds: [String] = []
  
  static public let shared = TipedUsers()
  
  private init() { }
}
