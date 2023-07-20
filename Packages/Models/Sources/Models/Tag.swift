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
    history.compactMap { Int($0.uses) }.reduce(0, +)
  }

  public var totalAccounts: Int {
    history.compactMap { Int($0.accounts) }.reduce(0, +)
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

  private enum CodingKeys: String, CodingKey {
    case id, name, url, statusesCount
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    url = try container.decode(URL.self, forKey: .url)
    do {
      statusesCount = try container.decode(String.self, forKey: .statusesCount)
    } catch DecodingError.typeMismatch {
      statusesCount = try String(container.decode(Int.self, forKey: .statusesCount))
    }
  }
}

extension Tag: Sendable {}
extension Tag.History: Sendable {}
extension FeaturedTag: Sendable {}

public struct TagGroup: Codable, Equatable, Hashable {
  public init(title: String, sfSymbolName: String, main: String, additional: [String]) {
    self.title = title
    self.sfSymbolName = sfSymbolName
    self.main = main
    self.additional = additional
  }

  public let title: String
  public let sfSymbolName: String
  public let main: String
  public let additional: [String]

  public var tags: [String] {
    [main] + additional
  }
}
