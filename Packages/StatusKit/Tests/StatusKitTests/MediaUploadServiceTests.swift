import Foundation
import Models
import UIKit
@testable import StatusKit
import XCTest

@MainActor
final class MediaUploadServiceTests: XCTestCase {
  func testUploadGifUsesClientAndMarksNeedsRefresh() async throws {
    let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).gif")
    try Data([0x47, 0x49, 0x46, 0x38]).write(to: url)
    let transferable = StatusEditor.GifFileTranseferable(url: url)
    let content = StatusEditor.MediaContainer.MediaContent.gif(
      transferable,
      previewImage: nil
    )
    let client = FakeUploadClient()
    client.attachment = makeAttachment(id: "media-1", urlString: nil)
    let service = StatusEditor.MediaUploadService()

    let result = try await service.upload(
      content: content,
      client: client,
      modeIsShareExtension: false,
      progressHandler: { _ in }
    )

    XCTAssertEqual(client.lastMimeType, "image/gif")
    XCTAssertEqual(result?.attachment.id, "media-1")
    XCTAssertEqual(result?.needsRefresh, true)
  }

  func testUploadImageUsesJpegMimeType() async throws {
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    format.scale = 1
    let image = UIGraphicsImageRenderer(
      size: .init(width: 64, height: 64),
      format: format
    ).image { context in
      UIColor.red.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
    }
    let content = StatusEditor.MediaContainer.MediaContent.image(image)
    let client = FakeUploadClient()
    client.attachment = makeAttachment(
      id: "media-2",
      urlString: "https://example.com/media.jpg"
    )
    let service = StatusEditor.MediaUploadService()

    let result = try await service.upload(
      content: content,
      client: client,
      modeIsShareExtension: true,
      progressHandler: { _ in }
    )

    XCTAssertEqual(client.lastMimeType, "image/jpeg")
    XCTAssertEqual(result?.attachment.id, "media-2")
    XCTAssertEqual(result?.needsRefresh, false)
    XCTAssertNotNil(result?.originalImage)
  }
}

@MainActor
private final class FakeUploadClient: StatusEditor.MediaUploadService.Client {
  var lastMimeType: String?
  var attachment: MediaAttachment?

  func uploadMedia(
    data _: Data,
    mimeType: String,
    progressHandler: @escaping @Sendable (Double) -> Void
  ) async throws -> MediaAttachment? {
    lastMimeType = mimeType
    progressHandler(0.5)
    return attachment
  }
}

private func makeAttachment(id: String, urlString: String?) -> MediaAttachment {
  let urlValue = urlString.map { "\"\($0)\"" } ?? "null"
  let data = """
  {
    "id": "\(id)",
    "type": "image",
    "url": \(urlValue),
    "previewUrl": null,
    "description": null,
    "meta": null
  }
  """.data(using: .utf8)!
  return try! JSONDecoder().decode(MediaAttachment.self, from: data)
}
