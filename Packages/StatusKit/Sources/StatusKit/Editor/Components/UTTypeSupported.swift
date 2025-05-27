import AVFoundation
@preconcurrency import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

extension StatusEditor {
  @MainActor
  struct UTTypeSupported {
    let value: String

    func loadItemContent(item: NSItemProvider) async throws -> Any? {
      if let transferable = await getVideoTransferable(item: item) {
        return transferable
      } else if let transferable = await getGifTransferable(item: item) {
        return transferable
      } else if let transferable = await getImageTansferable(item: item) {
        return transferable
      } else {
        return await withCheckedContinuation { continuation in
          item.loadItem(forTypeIdentifier: value) { result, error in
            if let url = result as? URL {
              continuation.resume(returning: url.absoluteString)
            } else if let text = result as? String {
              continuation.resume(returning: text)
            } else if let image = result as? UIImage {
              continuation.resume(returning: image)
            } else {
              continuation.resume(returning: nil)
            }
          }
        }
      }
    }

    private func getVideoTransferable(item: NSItemProvider) async -> MovieFileTranseferable? {
      await withCheckedContinuation { continuation in
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
      await withCheckedContinuation { continuation in
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
      await withCheckedContinuation { continuation in
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
}

extension StatusEditor {
  final class MovieFileTranseferable: Transferable, Sendable {
    let url: URL

    init(url: URL) {
      self.url = url
      _ = url.startAccessingSecurityScopedResource()
    }

    deinit {
      url.stopAccessingSecurityScopedResource()
    }

    static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(importedContentType: .movie) { receivedTransferrable in
        MovieFileTranseferable(url: receivedTransferrable.localURL)
      }
      FileRepresentation(importedContentType: .video) { receivedTransferrable in
        MovieFileTranseferable(url: receivedTransferrable.localURL)
      }
    }
  }

  final class GifFileTranseferable: Transferable, Sendable {
    let url: URL

    init(url: URL) {
      self.url = url
      _ = url.startAccessingSecurityScopedResource()
    }

    deinit {
      url.stopAccessingSecurityScopedResource()
    }

    var data: Data? {
      try? Data(contentsOf: url)
    }

    static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(importedContentType: .gif) { receivedTransferrable in
        GifFileTranseferable(url: receivedTransferrable.localURL)
      }
    }
  }
}

extension StatusEditor {
  public final class ImageFileTranseferable: Transferable, Sendable {
    public let url: URL

    init(url: URL) {
      self.url = url
      _ = url.startAccessingSecurityScopedResource()
    }

    deinit {
      url.stopAccessingSecurityScopedResource()
    }

    public static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(importedContentType: .image) { receivedTransferrable in
        ImageFileTranseferable(url: receivedTransferrable.localURL)
      }
    }
  }
}

extension ReceivedTransferredFile {
  public var localURL: URL {
    if isOriginalFile {
      return file
    }
    let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(file.pathExtension)")
    try? FileManager.default.copyItem(at: file, to: copy)
    return copy
  }
}

extension URL {
  public func mimeType() -> String {
    if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
      mimeType
    } else {
      "application/octet-stream"
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
