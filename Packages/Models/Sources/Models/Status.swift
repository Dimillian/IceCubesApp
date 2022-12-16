import Foundation

public protocol AnyStatus {
  var id: String { get }
  var content: String { get }
  var account: Account { get }
  var createdAt: String { get }
}

public struct Status: AnyStatus, Codable, Identifiable {
  public let id: String
  public let content: String
  public let account: Account
  public let createdAt: String
  public let reblog: ReblogStatus?
}

public struct ReblogStatus: AnyStatus, Codable, Identifiable {
  public let id: String
  public let content: String
  public let account: Account
  public let createdAt: String
}
