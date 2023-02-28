import Foundation

public struct StatusContext: Decodable {
  public let ancestors: [Status]
  public let descendants: [Status]

  public static func empty() -> StatusContext {
    .init(ancestors: [], descendants: [])
  }
}

extension StatusContext: Sendable {}
