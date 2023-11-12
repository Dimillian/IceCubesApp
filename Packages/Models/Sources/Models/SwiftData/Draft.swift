import Foundation
import SwiftData
import SwiftUI

@Model public class Draft {
  public var content: String = ""
  public var creationDate: Date = Date()

  public init(content: String) {
    self.content = content
    creationDate = Date()
  }
}
