import Foundation

@Observable
@MainActor
public class TipedUsers {
  public var usersIds: [String] = []
  
  public var tipedUserCount: Int = 0
  
  static public let shared = TipedUsers()
  
  private init() { }
}
