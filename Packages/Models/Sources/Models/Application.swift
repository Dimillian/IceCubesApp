import Foundation

public struct Application: Codable, Identifiable, Hashable, Equatable, Sendable {
  public var id: String {
    name
  }

  public let name: String
  public let website: URL?
}

public extension Application {
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    name = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
    website = try? values.decodeIfPresent(URL.self, forKey: .website)
  }
}
