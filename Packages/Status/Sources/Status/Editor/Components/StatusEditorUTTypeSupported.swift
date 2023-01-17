import Foundation
import UIKit

@MainActor
enum StatusEditorUTTypeSupported: String, CaseIterable {
  case url = "public.url"
  case text = "public.text"
  case plaintext = "public.plain-text"
  case image = "public.image"
  case jpeg = "public.jpeg"
  case png = "public.png"

  func loadItemContent(item: NSItemProvider) async throws -> Any? {
    let result = try await item.loadItem(forTypeIdentifier: rawValue)
    if self == .jpeg || self == .png,
       let imageURL = result as? URL,
       let data = try? Data(contentsOf: imageURL),
       let image = UIImage(data: data)
    {
      return image
    }
    if let url = result as? URL {
      return url.absoluteString
    } else if let text = result as? String {
      return text
    } else if let image = result as? UIImage {
      return image
    } else {
      return nil
    }
  }
}
