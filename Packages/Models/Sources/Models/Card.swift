import Foundation

public struct Card: Codable {
  public let url: URL
  public let title: String?
  public let description: String?
  public let type: String
  public let image: URL?
}
