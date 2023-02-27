import AVFoundation
import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
enum StatusEditorUTTypeSupported: String, CaseIterable {
  case url = "public.url"
  case text = "public.text"
  case plaintext = "public.plain-text"
  case image = "public.image"
  case jpeg = "public.jpeg"
  case png = "public.png"
  case tiff = "public.tiff"

  case video = "public.video"
  case movie = "public.movie"
  case mp4 = "public.mpeg-4"
  case gif = "public.gif"
  case gif2 = "com.compuserve.gif"
  case quickTimeMovie = "com.apple.quicktime-movie"

  case uiimage = "com.apple.uikit.image"

  // Have to implement this manually here due to compiler not implicitly
  // inserting `nonisolated`, which leads to a warning:
  //
  //     Main actor-isolated static property 'allCases' cannot be used to
  //     satisfy nonisolated protocol requirement
  //
  nonisolated public static var allCases: [StatusEditorUTTypeSupported] {
    [.url, .text, .plaintext, .image, .jpeg, .png, .tiff, .video,
     .movie, .mp4, .gif, .gif2, .quickTimeMovie, .uiimage]
  }
  
  static func types() -> [UTType] {
    [.url, .text, .plainText, .image, .jpeg, .png, .tiff, .video, .mpeg4Movie, .gif, .movie, .quickTimeMovie]
  }

  var isVideo: Bool {
    switch self {
    case .video, .movie, .mp4, .quickTimeMovie:
      return true
    default:
      return false
    }
  }

  var isGif: Bool {
    switch self {
    case .gif, .gif2:
      return true
    default:
      return false
    }
  }

  func loadItemContent(item: NSItemProvider) async throws -> Any? {
    // Many warnings here about non-sendable type `[AnyHashable: Any]?` crossing
    // actor boundaries. Many Radars have been filed.
    let result = try await item.loadItem(forTypeIdentifier: rawValue)
    if isVideo, let transferable = await getVideoTransferable(item: item) {
      return transferable
    } else if isGif, let transferable = await getGifTransferable(item: item) {
      return transferable
    }
    if self == .jpeg || self == .png || self == .tiff || self == .image || self == .uiimage {
      if let image = result as? UIImage {
        return image
      } else if let imageURL = result as? URL,
                let data = try? Data(contentsOf: imageURL),
                let image = UIImage(data: data)
      {
        return image
      } else if let data = result as? Data,
                let image = UIImage(data: data)
      {
        return image
      } else if let transferable = await getImageTansferable(item: item) {
        return transferable
      }
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

  private func getVideoTransferable(item: NSItemProvider) async -> MovieFileTranseferable? {
    return await withCheckedContinuation { continuation in
      _ = item.loadTransferable(type: MovieFileTranseferable.self) { result in
        switch result {
        case let .success(success):
          continuation.resume(with: .success(success))
        case .failure:
          continuation.resume(with: .success(nil))
        }
      }
    }
  }

  private func getGifTransferable(item: NSItemProvider) async -> GifFileTranseferable? {
    return await withCheckedContinuation { continuation in
      _ = item.loadTransferable(type: GifFileTranseferable.self) { result in
        switch result {
        case let .success(success):
          continuation.resume(with: .success(success))
        case .failure:
          continuation.resume(with: .success(nil))
        }
      }
    }
  }

  private func getImageTansferable(item: NSItemProvider) async -> ImageFileTranseferable? {
    return await withCheckedContinuation { continuation in
      _ = item.loadTransferable(type: ImageFileTranseferable.self) { result in
        switch result {
        case let .success(success):
          continuation.resume(with: .success(success))
        case .failure:
          continuation.resume(with: .success(nil))
        }
      }
    }
  }
}

struct MovieFileTranseferable: Transferable {
  private let url: URL
  var compressedVideoURL: URL? {
    get async {
      await withCheckedContinuation { continuation in
        let urlAsset = AVURLAsset(url: url, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1920x1080) else {
          continuation.resume(returning: nil)
          return
        }
        let outputURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(url.pathExtension)")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () in
          continuation.resume(returning: outputURL)
        }
      }
    }
  }

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .movie) { movie in
      SentTransferredFile(movie.url)
    } importing: { received in
      Self(url: localURLFor(received: received))
    }
  }
}

struct ImageFileTranseferable: Transferable {
  let url: URL

  lazy var data: Data? = try? Data(contentsOf: url)
  lazy var image: UIImage? = UIImage(data: data ?? Data())

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .image) { image in
      SentTransferredFile(image.url)
    } importing: { received in
      Self(url: localURLFor(received: received))
    }
  }
}

struct GifFileTranseferable: Transferable {
  let url: URL

  var data: Data? {
    try? Data(contentsOf: url)
  }

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .gif) { gif in
      SentTransferredFile(gif.url)
    } importing: { received in
      Self(url: localURLFor(received: received))
    }
  }
}

private func localURLFor(received: ReceivedTransferredFile) -> URL {
  let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(received.file.pathExtension)")
  try? FileManager.default.copyItem(at: received.file, to: copy)
  return copy
}

public extension URL {
  func mimeType() -> String {
    if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
      return mimeType
    } else {
      return "application/octet-stream"
    }
  }
}

extension UIImage {
  func resized(to size: CGSize) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }
}
