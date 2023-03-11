import Foundation
import UIKit
import AVFoundation

actor StatusEditorCompressor {
  enum CompressorError: Error {
    case noData
  }
  
  func compressImageFrom(url: URL) async -> Data? {
    return await withCheckedContinuation{ continuation in
      let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
      guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
        continuation.resume(returning: nil)
        return
      }
      
      let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: 4096,
      ] as CFDictionary
      
      guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
        continuation.resume(returning: nil)
        return
      }
      
      let data = NSMutableData()
      guard let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
        continuation.resume(returning: nil)
        return
      }
      
      let isPNG: Bool = {
        guard let utType = cgImage.utType else { return false }
        return (utType as String) == UTType.png.identifier
        
      }()
      
      let destinationProperties = [
        kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75
      ] as CFDictionary
      
      CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
      CGImageDestinationFinalize(imageDestination)
      
      continuation.resume(returning: data as Data)
    }
  }
  
  func compressImageForUpload(_ image: UIImage) async throws -> Data {
    var image = image
    if image.size.height > 5000 || image.size.width > 5000 {
      image = image.resized(to: .init(width: image.size.width / 4,
                                      height: image.size.height / 4))
    }
    
    guard var imageData = image.jpegData(compressionQuality: 0.8) else {
      throw CompressorError.noData
    }
        
    let maxSize: Int = 10 * 1024 * 1024

    if imageData.count > maxSize {
      while imageData.count > maxSize {
        guard let compressedImage = UIImage(data: imageData),
              let compressedData = compressedImage.jpegData(compressionQuality: 0.8) else {
          throw CompressorError.noData
        }
        imageData = compressedData
      }
    }
    
    return imageData
  }
  
  func compressVideo(_ url: URL) async -> URL? {
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
