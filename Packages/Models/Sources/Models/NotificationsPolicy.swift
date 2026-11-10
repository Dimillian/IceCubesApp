import Foundation
import SwiftUI

public struct NotificationsPolicy: Codable, Sendable {
  public enum Policy: String, Codable, Sendable, CaseIterable, Hashable {
    case accept, filter, drop

    public var localized: LocalizedStringKey {
      switch self {
      case .accept:
        "Accept"
      case .filter:
        "Filter"
      case .drop:
        "Drop"
      }
    }
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
