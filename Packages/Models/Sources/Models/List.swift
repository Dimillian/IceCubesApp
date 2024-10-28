import Foundation

public struct List: Codable, Identifiable, Equatable, Hashable {
  public let id: String
  public let title: String
  public let repliesPolicy: RepliesPolicy?
  public let exclusive: Bool?

  public enum RepliesPolicy: String, Sendable, Codable, CaseIterable, Identifiable {
    public var id: String {
      rawValue
    }

    case followed, list, none
  }

  public init(
    id: String, title: String, repliesPolicy: RepliesPolicy? = nil, exclusive: Bool? = nil
  ) {
    self.id = id
    self.title = title
    self.repliesPolicy = repliesPolicy
    self.exclusive = exclusive
  }
}

extension List: Sendable {}
