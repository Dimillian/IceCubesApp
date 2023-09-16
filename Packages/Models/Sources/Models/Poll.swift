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
    public let votesCount: Int?
  }

  public let id: String
  public let expiresAt: NullableString
  public let expired: Bool
  public let multiple: Bool
  public let votesCount: Int
  public let votersCount: Int?
  public let voted: Bool?
  public let ownVotes: [Int]?
  public let options: [Option]

  // the votersCount can be null according to the docs when multiple is false.
  // Didn't find that to be true, but we make sure
  public var safeVotersCount: Int {
    votersCount ?? votesCount
  }
}

public struct NullableString: Codable, Equatable, Hashable {
  public let value: ServerDate?

  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      value = try container.decode(ServerDate.self)
    } catch {
      value = nil
    }
  }
}

extension Poll: Sendable {}
extension Poll.Option: Sendable {}
extension NullableString: Sendable {}
