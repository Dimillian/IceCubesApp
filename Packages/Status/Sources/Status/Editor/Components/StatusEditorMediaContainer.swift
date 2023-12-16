import Foundation
import Models
import PhotosUI
import SwiftUI
import UIKit

struct StatusEditorMediaContainer: Identifiable {
  let id: String
  let image: UIImage?
  let movieTransferable: MovieFileTranseferable?
  let gifTransferable: GifFileTranseferable?
  let mediaAttachment: MediaAttachment?
  let error: Error?
}
