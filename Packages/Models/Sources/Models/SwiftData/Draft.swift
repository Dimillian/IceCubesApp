import Foundation
import SwiftData
import SwiftUI

@Model public class Draft {
  @Attribute(.unique) public var id: UUID
  public var content: String
  public var creationDate: Date

  public init(content: String) {
    id = UUID()
    self.content = content
    creationDate = Date()
  }
}
