import CoreTransferable
import SwiftUI
import UIKit

struct MediaUIImageTransferable: Codable, Transferable {
  let url: URL

  func fetchAsImage() -> Image {
    let data = try? Data(contentsOf: url)
    guard let data, let uiimage = UIImage(data: data) else {
      return Image(systemName: "photo")
    }
    return Image(uiImage: uiimage)
  }

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { media in
      media.fetchAsImage()
    }
  }
}
