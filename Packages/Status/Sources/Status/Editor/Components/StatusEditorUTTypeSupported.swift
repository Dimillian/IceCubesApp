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

  case video = "public.video"
  case movie = "public.movie"
  case mp4 = "public.mpeg-4"
  case gif = "public.gif"
  case quickTimeMovie = "com.apple.quicktime-movie"

  static func types() -> [UTType] {
    [.url, .text, .plainText, .image, .jpeg, .png, .video, .mpeg4Movie, .gif, .movie, .quickTimeMovie]
  }

  var isVideo: Bool {
    switch self {
    case .video, .movie, .mp4, .gif, .quickTimeMovie:
      return true
    default:
      return false
    }
  }

  func loadItemContent(item: NSItemProvider) async throws -> Any? {
    let result = try await item.loadItem(forTypeIdentifier: rawValue)
    if isVideo, let transferable = await getVideoTransferable(item: item) {
      return transferable
    }
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
}

struct MovieFileTranseferable: Transferable {
  private let url: URL
  var compressedVideoURL: URL? {
    get async {
      await withCheckedContinuation { continuation in
        let urlAsset = AVURLAsset(url: url, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
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
      let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(received.file.pathExtension)")
      try FileManager.default.copyItem(at: received.file, to: copy)
      return Self(url: copy)
    }
  }
}

struct ImageFileTranseferable: Transferable {
  let url: URL

  lazy var data: Data? = try? Data(contentsOf: url)
  lazy var compressedData: Data? = image?.jpegData(compressionQuality: 0.90)
  lazy var image: UIImage? = UIImage(data: data ?? Data())

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .image) { image in
      SentTransferredFile(image.url)
    } importing: { received in
      let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(received.file.pathExtension)")
      try FileManager.default.copyItem(at: received.file, to: copy)
      return Self(url: copy)
    }
  }
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
