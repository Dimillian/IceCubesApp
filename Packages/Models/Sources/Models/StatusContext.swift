import Foundation

public struct StatusContext: Decodable {
  public let ancestors: [Status]
  public let descendants: [Status]
}
