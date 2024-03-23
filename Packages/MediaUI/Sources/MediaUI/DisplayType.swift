import Models
import SwiftUI

enum DisplayType {
  case image
  case av

  init(from attachmentType: MediaAttachment.SupportedType) {
    switch attachmentType {
    case .image:
      self = .image
    case .video, .gifv, .audio:
      self = .av
    }
  }
}
