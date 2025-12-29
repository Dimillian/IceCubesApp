import Models
@testable import StatusKit
import XCTest

@MainActor
final class MediaDescriptionServiceTests: XCTestCase {
  func testApplyPendingAltTextAddsAttributesForUploadedContainers() {
    var store = StatusEditor.MediaDescriptionService.PendingStore()
    store.altTextByContainerId["c1"] = "Alt 1"
    store.altTextByContainerId["c2"] = "Alt 2"
    let service = StatusEditor.MediaDescriptionService()

    let uploaded = StatusEditor.MediaContainer.uploaded(
      id: "c1",
      attachment: makeAttachment(id: "m1"),
      originalImage: nil
    )
    let pending = StatusEditor.MediaContainer.pending(
      id: "c2",
      image: makeImage()
    )

    service.applyPendingAltText(
      mediaContainers: [uploaded, pending],
      store: &store
    )

    XCTAssertEqual(store.mediaAttributes.count, 1)
    XCTAssertEqual(store.mediaAttributes.first?.id, "m1")
    XCTAssertEqual(store.mediaAttributes.first?.description, "Alt 1")
  }

  func testBuildMediaAttributeAppendsToStore() {
    var store = StatusEditor.MediaDescriptionService.PendingStore()
    let service = StatusEditor.MediaDescriptionService()
    let attachment = makeAttachment(id: "m2")

    service.buildMediaAttribute(
      attachment: attachment,
      description: "Alt 2",
      store: &store
    )

    XCTAssertEqual(store.mediaAttributes.count, 1)
    XCTAssertEqual(store.mediaAttributes.first?.id, "m2")
    XCTAssertEqual(store.mediaAttributes.first?.description, "Alt 2")
  }

  func testAddDescriptionUsesClient() async {
    let service = StatusEditor.MediaDescriptionService()
    let client = FakeDescriptionClient()
    client.updated = makeAttachment(id: "m3")
    let container = StatusEditor.MediaContainer.uploaded(
      id: "c3",
      attachment: makeAttachment(id: "m3"),
      originalImage: nil
    )

    let updated = await service.addDescription(
      container: container,
      description: "Alt 3",
      client: client
    )

    XCTAssertEqual(client.lastDescription, "Alt 3")
    XCTAssertEqual(updated?.id, "m3")
  }
}

@MainActor
private final class FakeDescriptionClient: StatusEditor.MediaDescriptionService.Client {
  var lastDescription: String?
  var updated: MediaAttachment?

  func updateDescription(mediaId _: String, description: String) async throws -> MediaAttachment {
    lastDescription = description
    return updated ?? makeAttachment(id: UUID().uuidString)
  }
}

private func makeAttachment(id: String) -> MediaAttachment {
  let data = """
  {
    "id": "\(id)",
    "type": "image",
    "url": "https://example.com/media/\(id).jpg",
    "previewUrl": null,
    "description": null,
    "meta": null
  }
  """.data(using: .utf8)!
  return try! JSONDecoder().decode(MediaAttachment.self, from: data)
}

private func makeImage() -> UIImage {
  makeOpaqueTestImage()
}
