import SwiftData
import SwiftUI
import Foundation

@Model public class LocalTimeline {
  public var instance: String
  public var creationDate: Date
  
  public init(instance: String) {
    self.instance = instance
    self.creationDate = Date()
  }
}
