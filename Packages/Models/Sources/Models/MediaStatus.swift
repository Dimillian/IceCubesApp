import Foundation

public struct MediaStatus: Sendable, Identifiable, Hashable {
  public var id: String {
    attachment.id
  }

  public let status: Status
  public let attachment: MediaAttachment

  public init(status: Status, attachment: MediaAttachment) {
    self.status = status
    self.attachment = attachment
  }
}
