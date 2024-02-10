import Foundation

public struct History: Codable, Identifiable, Sendable, Equatable, Hashable {
  public var id: String {
    day
  }

  public let day: String
  public let accounts: String
  public let uses: String
}
