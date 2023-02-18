import Foundation

public struct Instance: Codable, Sendable {
  public struct Stats: Codable, Sendable {
    public let userCount: Int
    public let statusCount: Int
    public let domainCount: Int
  }

  public struct Configuration: Codable, Sendable {
    public struct Statuses: Codable, Sendable {
      public let maxCharacters: Int
      public let maxMediaAttachments: Int
    }

    public struct Polls: Codable, Sendable {
      public let maxOptions: Int
      public let maxCharactersPerOption: Int
      public let minExpiration: Int
      public let maxExpiration: Int
    }

    public let statuses: Statuses
    public let polls: Polls
  }

  public struct Rule: Codable, Identifiable, Sendable {
    public let id: String
    public let text: String
  }

  public struct URLs: Codable, Sendable {
    public let streamingApi: URL?
  }

  public let title: String
  public let shortDescription: String
  public let email: String
  public let version: String
  public let stats: Stats
  public let languages: [String]?
  public let registrations: Bool
  public let thumbnail: URL?
  public let configuration: Configuration?
  public let rules: [Rule]?
  public let urls: URLs?
}
