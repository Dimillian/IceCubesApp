import Foundation

public struct Card: Codable, Identifiable {
  public var id: String {
    url.absoluteString
  }
  
  public let url: URL
  public let title: String?
  public let description: String?
  public let type: String
  public let image: URL?
}
