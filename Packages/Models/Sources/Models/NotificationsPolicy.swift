import Foundation

public struct NotificationsPolicy: Codable, Sendable {
  public enum Policy: String, Codable, Sendable, CaseIterable, Hashable {
    case accept, filter, drop
  }

  public var forNotFollowing: Policy
  public var forNotFollowers: Policy
  public var forNewAccounts: Policy
  public var forPrivateMentions: Policy
  public var forLimitedAccounts: Policy
  public let summary: Summary

  public struct Summary: Codable, Sendable {
    public let pendingRequestsCount: Int
    public let pendingNotificationsCount: Int
  }
}
