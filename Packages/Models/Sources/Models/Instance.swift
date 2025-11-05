import Foundation

public struct Instance: Codable, Sendable, Hashable {
  public static func == (lhs: Instance, rhs: Instance) -> Bool {
    lhs.title == rhs.title && lhs.domain == rhs.domain
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(title)
    hasher.combine(domain)
  }

  public struct Usage: Codable, Sendable {
    public struct Users: Codable, Sendable {
      public let activeMonth: Int?
    }
    public let users: Users?
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

  public struct APIVersions: Codable, Sendable {
    public let mastodon: Int?
  }

  public struct Contact: Codable, Sendable {
    public let account: Account?
    public let email: String
  }

  public struct Registrations: Codable, Sendable {
    public let enabled: Bool
  }

  public struct Thumbnail: Codable, Sendable {
    public let url: URL?
  }

  public let title: String
  public let domain: String
  public let description: String?
  public let shortDescription: String?
  public let version: String
  public let apiVersions: APIVersions?
  public let usage: Usage?
  public let languages: [String]?
  public let registrations: Registrations
  public let thumbnail: Thumbnail
  public let configuration: Configuration?
  public let rules: [Rule]?
  public let urls: URLs?
  public let contact: Contact
}
