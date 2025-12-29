import Foundation
import UIKit

extension StatusEditor {
  @MainActor
  struct MediaIngestionService {
    struct Result {
      var containers: [MediaContainer]
      var initialText: String
      var hadError: Bool
    }

    func ingest(
      items: [NSItemProvider],
      makeVideoPreview: (URL) async -> UIImage?
    ) async -> Result {
      var containers: [MediaContainer] = []
      var initialText = ""
      var hadError = false

      for item in items {
        guard let identifier = item.registeredTypeIdentifiers.first else { continue }
        let handledItemType = UTTypeSupported(value: identifier)
        do {
          let compressor = Compressor()
          let content = try await handledItemType.loadItemContent(item: item)
          if let text = content as? String {
            initialText += "\(text) "
          } else if let image = content as? UIImage {
            containers.append(
              MediaContainer.pending(
                id: UUID().uuidString,
                image: image
              )
            )
          } else if let content = content as? ImageFileTranseferable,
            let compressedData = await compressor.compressImageFrom(url: content.url),
            let image = UIImage(data: compressedData)
          {
            containers.append(
              MediaContainer.pending(
                id: UUID().uuidString,
                image: image
              )
            )
          } else if let video = content as? MovieFileTranseferable {
            containers.append(
              MediaContainer.pending(
                id: UUID().uuidString,
                video: video,
                preview: await makeVideoPreview(video.url)
              )
            )
          } else if let gif = content as? GifFileTranseferable {
            containers.append(
              MediaContainer.pending(
                id: UUID().uuidString,
                gif: gif,
                preview: nil
              )
            )
          }
        } catch {
          hadError = true
        }
      }

      return Result(containers: containers, initialText: initialText, hadError: hadError)
    }
  }
}
