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

    let input = StatusEditor.MediaUploadService.UploadInput(
      id: "gif-1",
      content: content,
      altText: nil
    )
    let result = await service.upload(
      input: input,
      client: client,
      modeIsShareExtension: false,
      policy: .init(),
      progressHandler: { _ in }
    )

    XCTAssertEqual(client.lastMimeType, "image/gif")
    switch result {
    case .success(let value):
      XCTAssertEqual(value.attachment.id, "media-1")
      XCTAssertEqual(value.needsRefresh, true)
    case .failure(let error):
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testUploadImageUsesJpegMimeType() async throws {
    let image = makeOpaqueTestImage()
    let content = StatusEditor.MediaContainer.MediaContent.image(image)
    let client = FakeUploadClient()
    client.attachment = makeAttachment(
      id: "media-2",
      urlString: "https://example.com/media.jpg"
    )
    let service = StatusEditor.MediaUploadService()

    let input = StatusEditor.MediaUploadService.UploadInput(
      id: "image-1",
      content: content,
      altText: nil
    )
    let result = await service.upload(
      input: input,
      client: client,
      modeIsShareExtension: true,
      policy: .init(),
      progressHandler: { _ in }
    )

    XCTAssertEqual(client.lastMimeType, "image/jpeg")
    switch result {
    case .success(let value):
      XCTAssertEqual(value.attachment.id, "media-2")
      XCTAssertEqual(value.needsRefresh, false)
      XCTAssertNotNil(value.originalImage)
    case .failure(let error):
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testUploadRequiresAltTextWhenConfigured() async throws {
    let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).gif")
    try Data([0x47, 0x49, 0x46, 0x38]).write(to: url)
    let transferable = StatusEditor.GifFileTranseferable(url: url)
    let content = StatusEditor.MediaContainer.MediaContent.gif(
      transferable,
      previewImage: nil
    )
    let client = FakeUploadClient()
    let service = StatusEditor.MediaUploadService()
    var policy = StatusEditor.MediaUploadService.UploadPolicy()
    policy.requiresAltText = true

    let result = await service.upload(
      input: .init(id: "gif-2", content: content, altText: nil),
      client: client,
      modeIsShareExtension: false,
      policy: policy,
      progressHandler: { _ in }
    )

    switch result {
    case .success:
      XCTFail("Expected missing alt text error")
    case .failure(let error):
      if case .missingAltText = error {
        XCTAssertEqual(client.uploadCalls, 0)
      } else {
        XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testUploadRespectsSizeLimit() async throws {
    let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).gif")
    try Data(repeating: 0x47, count: 16).write(to: url)
    let transferable = StatusEditor.GifFileTranseferable(url: url)
    let content = StatusEditor.MediaContainer.MediaContent.gif(
      transferable,
      previewImage: nil
    )
    let client = FakeUploadClient()
    let service = StatusEditor.MediaUploadService()
    var policy = StatusEditor.MediaUploadService.UploadPolicy()
    policy.maxBytes = 4

    let result = await service.upload(
      input: .init(id: "gif-3", content: content, altText: "ok"),
      client: client,
      modeIsShareExtension: false,
      policy: policy,
      progressHandler: { _ in }
    )

    switch result {
    case .success:
      XCTFail("Expected size limit error")
    case .failure(let error):
      if case .sizeLimitExceeded = error {
        XCTAssertEqual(client.uploadCalls, 0)
      } else {
        XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testUploadRetriesOnServerError() async throws {
    let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).gif")
    try Data([0x47, 0x49, 0x46, 0x38]).write(to: url)
    let transferable = StatusEditor.GifFileTranseferable(url: url)
    let content = StatusEditor.MediaContainer.MediaContent.gif(
      transferable,
      previewImage: nil
    )
    let client = FakeUploadClient()
    client.errors = [makeServerError(message: "Fail", httpCode: 500)]
    client.attachment = makeAttachment(id: "media-3", urlString: "https://example.com/media.gif")
    let service = StatusEditor.MediaUploadService()
    var policy = StatusEditor.MediaUploadService.UploadPolicy()
    policy.retryCount = 1
    policy.retryBackoffBase = .zero

    let result = await service.upload(
      input: .init(id: "gif-4", content: content, altText: "ok"),
      client: client,
      modeIsShareExtension: false,
      policy: policy,
      progressHandler: { _ in }
    )

    XCTAssertEqual(client.uploadCalls, 2)
    switch result {
    case .success(let value):
      XCTAssertEqual(value.attachment.id, "media-3")
    case .failure(let error):
      XCTFail("Unexpected error: \(error)")
    }
  }
}

@MainActor
private final class FakeUploadClient: StatusEditor.MediaUploadService.Client {
  var lastMimeType: String?
  var attachment: MediaAttachment?
  var errors: [Error] = []
  var uploadCalls = 0

  func uploadMedia(
    data _: Data,
    mimeType: String,
    progressHandler: @escaping @Sendable (Double) -> Void
  ) async throws -> MediaAttachment? {
    lastMimeType = mimeType
    uploadCalls += 1
    progressHandler(0.5)
    if !errors.isEmpty {
      throw errors.removeFirst()
    }
    return attachment
  }

  func fetchMedia(id _: String) async throws -> MediaAttachment {
    if let attachment {
      return attachment
    }
    return makeAttachment(id: UUID().uuidString, urlString: nil)
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

private func makeServerError(message: String, httpCode: Int) -> ServerError {
  let data = """
  {
    "error": "\(message)",
    "httpCode": \(httpCode)
  }
  """.data(using: .utf8)!
  return try! JSONDecoder().decode(ServerError.self, from: data)
}
