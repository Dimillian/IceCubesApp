import AVFoundation
import Foundation
import UIKit

extension StatusEditor {
  public actor Compressor {
    public init() {}

    enum CompressorError: Error {
      case noData
    }

    public func compressImageFrom(url: URL) async -> Data? {
      await withCheckedContinuation { continuation in
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
          continuation.resume(returning: nil)
          return
        }

        let maxPixelSize: Int =
          if Bundle.main.bundlePath.hasSuffix(".appex") {
            1536
          } else {
            4096
          }

        let downsampleOptions =
          [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
          ] as [CFString: Any] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
          continuation.resume(returning: nil)
          return
        }

        let data = NSMutableData()
        guard
          let imageDestination = CGImageDestinationCreateWithData(
            data, UTType.jpeg.identifier as CFString, 1, nil)
        else {
          continuation.resume(returning: nil)
          return
        }

        let isPNG: Bool = {
          guard let utType = cgImage.utType else { return false }
          return (utType as String) == UTType.png.identifier
        }()

        let destinationProperties =
          [
            kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75
          ] as CFDictionary

        CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
        CGImageDestinationFinalize(imageDestination)

        continuation.resume(returning: data as Data)
      }
    }

    public func compressImageForUpload(
      _ image: UIImage,
      maxSize: Int = 10 * 1024 * 1024,
      maxHeight: Double = 5000,
      maxWidth: Double = 5000
    ) async throws -> Data {
      var image = image

      if image.size.height > maxHeight || image.size.width > maxWidth {
        let heightFactor = image.size.height / maxHeight
        let widthFactor = image.size.width / maxWidth
        let maxFactor = max(heightFactor, widthFactor)

        image = image.resized(
          to: .init(
            width: image.size.width / maxFactor,
            height: image.size.height / maxFactor))
      }

      guard var imageData = image.jpegData(compressionQuality: 0.8) else {
        throw CompressorError.noData
      }

      var compressionQualityFactor: CGFloat = 0.8
      if imageData.count > maxSize {
        while imageData.count > maxSize && compressionQualityFactor >= 0 {
          guard let compressedImage = UIImage(data: imageData),
            let compressedData = compressedImage.jpegData(
              compressionQuality: compressionQualityFactor)
          else {
            throw CompressorError.noData
          }

          imageData = compressedData
          compressionQualityFactor -= 0.1
        }
      }

      if imageData.count > maxSize && compressionQualityFactor <= 0 {
        throw CompressorError.noData
      }

      return imageData
    }

    func compressVideo(_ url: URL) async -> URL? {
      let urlAsset = AVURLAsset(url: url, options: nil)
      let presetName: String =
        if Bundle.main.bundlePath.hasSuffix(".appex") {
          AVAssetExportPreset1280x720
        } else {
          AVAssetExportPreset1920x1080
        }
      guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: presetName)
      else {
        return nil
      }
      let outputURL = URL.temporaryDirectory.appending(
        path: "\(UUID().uuidString).\(url.pathExtension)")
      exportSession.outputURL = outputURL
      exportSession.outputFileType = .mp4
      exportSession.shouldOptimizeForNetworkUse = true
      do {
        try await exportSession.export(to: outputURL, as: .mp4)
        return outputURL
      } catch {
        return nil
      }
    }
  }
}
