import Foundation

public struct Card: Codable, Identifiable, Equatable, Hashable {
  public var id: String {
    url
  }

  public let url: String
  public let title: String?
  public let description: String?
  public let type: String
  public let image: URL?
}
