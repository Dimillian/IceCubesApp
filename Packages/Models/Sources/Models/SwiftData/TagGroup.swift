import Foundation
import SwiftData
import SwiftUI

@Model public class TagGroup: Equatable {
  public var title: String = ""
  public var symbolName: String = ""
  public var tags: [String] = []
  public var creationDate: Date = Date()

  public init(title: String, symbolName: String, tags: [String]) {
    self.title = title
    self.symbolName = symbolName
    self.tags = tags
    creationDate = Date()
  }
}
