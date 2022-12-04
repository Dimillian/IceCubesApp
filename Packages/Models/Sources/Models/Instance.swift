import Foundation

public struct Instance: Codable {
  public struct Stats: Codable {
    public let userCount: Int
    public let statusCount: Int
    public let domainCount: Int
  }
  
  public let title: String
  public let shortDescription: String
  public let email: String
  public let version: String
  public let stats: Stats
  public let languages: [String]
  public let registrations: Bool
  public let thumbnail: URL?
}
