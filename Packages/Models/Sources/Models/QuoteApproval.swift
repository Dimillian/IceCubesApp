import Foundation

public struct QuoteApproval: Codable, Equatable, Hashable, Sendable {
  public enum QuoteAppproveStatus: String, Codable, Sendable {
    case automatic, manual, denied, unknown
  }

  public let currentUser: QuoteAppproveStatus
  public let automatic: [String]
  public let manual: [String]
}
