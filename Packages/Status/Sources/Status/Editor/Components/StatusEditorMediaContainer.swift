import Foundation
import Models
import PhotosUI
import SwiftUI
import UIKit

struct StatusEditorMediaContainer: Identifiable {
  let id = UUID().uuidString
  let image: UIImage?
  let movieTransferable: MovieFileTranseferable?
  let mediaAttachment: MediaAttachment?
  let error: Error?
}
