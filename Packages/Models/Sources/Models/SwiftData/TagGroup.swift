import SwiftData
import SwiftUI
import Foundation

@Model public class TagGroup: Equatable {
  public var title: String
  public var symbolName: String
  public var tags: [String]
  public var creationDate: Date
  
  public init(title: String, symbolName: String, tags: [String]) {
    self.title = title
    self.symbolName = symbolName
    self.tags = tags
    self.creationDate = Date()
  }
}

public struct LegacyTagGroup: Codable, Equatable, Hashable {
  public let title: String
  public let sfSymbolName: String
  public let main: String
  public let additional: [String]

  public var tags: [String] {
    [main] + additional
  }
}
