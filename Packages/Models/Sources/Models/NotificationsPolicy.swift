import Foundation

public struct NotificationsPolicy: Codable, Sendable {
  public var filterNotFollowing: Bool
  public var filterNotFollowers: Bool
  public var filterNewAccounts: Bool
  public var filterPrivateMentions: Bool
  public let summary: Summary

  public struct Summary: Codable, Sendable {
    public let pendingRequestsCount: String
    public let pendingNotificationsCount: String
  }
}
