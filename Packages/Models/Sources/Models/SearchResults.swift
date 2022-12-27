import Foundation

public struct SearchResults: Decodable {
  public let accounts: [Account]
  public let statuses: [Status]
  public let hashtags: [Tag]
}
