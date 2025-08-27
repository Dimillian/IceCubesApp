import Combine
import Models
import QuickLook
import SwiftUI

@MainActor
@Observable public class QuickLook {
  public var selectedMediaAttachment: MediaAttachment?
  public var mediaAttachments: [MediaAttachment] = []
  
  @ObservationIgnored
  public var namespace: Namespace.ID?

  public static let shared = QuickLook()

  private init() {}

  public func prepareFor(
    selectedMediaAttachment: MediaAttachment, mediaAttachments: [MediaAttachment]
  ) {
    self.selectedMediaAttachment = selectedMediaAttachment
    self.mediaAttachments = mediaAttachments
  }
}
