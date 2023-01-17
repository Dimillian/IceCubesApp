import Foundation

public struct StreamMessage: Encodable {
  public let type: String
  public let stream: String

  public init(type: String, stream: String) {
    self.type = type
    self.stream = stream
  }
}
