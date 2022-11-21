import Foundation

public struct Account: Codable, Identifiable {
  public let id: String
  public let username: String
  public let displayName: String
  public let avatar: URL
}

// MARL: Preview Content
public extension Account {
    static let preview: Account = Account(id: "1234567890", username: "@johnm@mastodon.social", displayName: "John Mastodon", avatar: URL(string: "https://files.mastodon.social/accounts/avatars/000/415/403/original/5fd8b8dba26e55f1.png")!)
}
