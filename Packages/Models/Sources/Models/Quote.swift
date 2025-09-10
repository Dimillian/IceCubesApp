import Foundation

public struct Quote: Codable, Sendable {
  public enum State: String, Codable, Sendable {
    case accepted, pending, rejected, revoked, deleted, unauthorized
  }

  public let state: State
  public let quotedStatus: Status?
}
