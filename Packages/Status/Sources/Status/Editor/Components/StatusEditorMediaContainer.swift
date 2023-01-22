import Foundation
import UIKit
import Models
import PhotosUI
import SwiftUI

struct StatusEditorMediaContainer: Identifiable {
  let id = UUID().uuidString
  let image: UIImage?
  let movieTransferable: MovieFileTranseferable?
  let mediaAttachment: MediaAttachment?
  let error: Error?
}
