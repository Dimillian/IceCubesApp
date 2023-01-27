import Foundation

public struct Poll: Codable, Equatable, Hashable {
  public static func == (lhs: Poll, rhs: Poll) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public struct Option: Identifiable, Codable {
    enum CodingKeys: String, CodingKey {
      case title, votesCount
    }

    public var id = UUID().uuidString
    public let title: String
    public let votesCount: Int
  }

  public let id: String
  public let expiresAt: NullableString
  public let expired: Bool
  public let multiple: Bool
  public let votesCount: Int
  public let voted: Bool?
  public let ownVotes: [Int]?
  public let options: [Option]
}

public struct NullableString: Codable, Equatable, Hashable {
  public let value: String?

  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      value = try container.decode(String.self)
    } catch {
      value = nil
    }
  }
}
