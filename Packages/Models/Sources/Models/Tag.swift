import Foundation

public struct Tag: Codable, Identifiable {
  
  public struct History: Codable {
    public let day: String
    public let accounts: String
    public let uses: String
  }
  
  public var id: String {
    name
  }
  
  public let name: String
  public let url: String
  public let following: Bool
  public let history: [History]
  
  public var totalUses: Int {
    history.compactMap{ Int($0.uses) }.reduce(0, +)
  }
  
  public var totalAccounts: Int {
    history.compactMap{ Int($0.accounts) }.reduce(0, +)
  }
}
