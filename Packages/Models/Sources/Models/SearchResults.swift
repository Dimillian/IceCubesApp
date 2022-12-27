import Foundation

public struct SearchResults: Decodable {
  enum CodingKeys: String, CodingKey {
    case accounts, statuses, hashtags
  }
  
  public let accounts: [Account]
  public var relationships: [Relationshionship] = []
  public let statuses: [Status]
  public let hashtags: [Tag]
}
