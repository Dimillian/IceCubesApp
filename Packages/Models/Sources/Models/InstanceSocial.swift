import Foundation

public struct InstanceSocial: Decodable, Identifiable, Sendable {
  public struct Info: Decodable, Sendable {
    public let shortDescription: String?
  }

  public let id: String
  public let name: String
  public let dead: Bool
  public let users: String
  public let activeUsers: Int?
  public let statuses: String
  public let thumbnail: URL?
  public let info: Info?
}
