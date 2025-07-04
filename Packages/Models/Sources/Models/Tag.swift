import Foundation

public struct Tag: Codable, Identifiable, Equatable, Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }

  public static func == (lhs: Tag, rhs: Tag) -> Bool {
    lhs.name == rhs.name && lhs.following == rhs.following
  }

  public var id: String {
    name
  }

  public let name: String
  public let url: String
  public let following: Bool
  public let history: [History]

  public var totalUses: Int {
    return history.compactMap { Int($0.uses) }.reduce(0, +)
  }

  public var totalAccounts: Int {
    return history.compactMap { Int($0.accounts) }.reduce(0, +)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    url = try container.decode(String.self, forKey: .url)
    do {
      history = try container.decode([History].self, forKey: .history)
    } catch DecodingError.keyNotFound {
      history = []
    }
    do {
      following = try container.decode(Bool.self, forKey: .following)
    } catch DecodingError.keyNotFound {
      following = false
    }
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
extension FeaturedTag: Sendable {}
