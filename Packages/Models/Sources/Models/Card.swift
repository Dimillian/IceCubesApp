import Foundation

public struct Card: Codable, Identifiable, Equatable, Hashable {
  public var id: String {
    url
  }

  public struct CardAuthor: Codable, Sendable, Identifiable, Equatable, Hashable {
    public var id: String {
      url
    }

    public let name: String
    public let url: String
    public let account: Account?
  }

  public let url: String
  public let title: String?
  public let authorName: String?
  public let description: String?
  public let providerName: String?
  public let type: String
  public let image: URL?
  public let width: CGFloat?
  public let height: CGFloat?
  public let history: [History]?
  public let authors: [CardAuthor]?
}

extension Card: Sendable {}
