import Foundation

public struct PushSubscription: Identifiable, Decodable {
  public struct Alerts: Decodable {
    public let follow: Bool
    public let favourite: Bool
    public let reblog: Bool
    public let mention: Bool
    public let poll: Bool
    public let status: Bool
  }

  public let id: Int
  public let endpoint: URL
  public let serverKey: String
  public let alerts: Alerts
}

extension PushSubscription: Sendable {}
extension PushSubscription.Alerts: Sendable {}
