import Foundation

public struct Tag: Codable, Identifiable, Equatable, Hashable {
  public struct History: Codable {
    public let day: String
    public let accounts: String
    public let uses: String
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
  
  public static func == (lhs: Tag, rhs: Tag) -> Bool {
    lhs.name == rhs.name
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

public struct FeaturedTag: Codable, Identifiable {
  public let id: String
  public let name: String
  public let url: URL
  public let statusesCount: String
  public var statusesCountInt: Int {
    Int(statusesCount) ?? 0
  }
}
