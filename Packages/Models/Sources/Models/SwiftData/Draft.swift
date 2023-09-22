import SwiftData
import SwiftUI
import Foundation

@Model public class Draft {
  @Attribute(.unique) public var id: UUID
  public var content: String
  public var creationDate: Date
  
  public init(content: String) {
    self.id = UUID()
    self.content = content
    self.creationDate = Date()
  }
}
