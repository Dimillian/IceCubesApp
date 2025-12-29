import Foundation
import UniformTypeIdentifiers
import UIKit
@testable import StatusKit
import XCTest

@MainActor
final class MediaIngestionServiceTests: XCTestCase {
  func testIngestTextItemBuildsInitialText() async {
    let item = NSItemProvider(
      item: "Hello" as NSString,
      typeIdentifier: UTType.plainText.identifier
    )
    let service = StatusEditor.MediaIngestionService()

    let result = await service.ingest(
      items: [item],
      makeVideoPreview: { _ in nil }
    )

    XCTAssertEqual(result.initialText, "Hello ")
    XCTAssertTrue(result.containers.isEmpty)
    XCTAssertFalse(result.hadError)
  }

  func testIngestImageItemBuildsContainer() async {
    let image = makeOpaqueTestImage()
    let item = NSItemProvider(object: image)
    let service = StatusEditor.MediaIngestionService()

    let result = await service.ingest(
      items: [item],
      makeVideoPreview: { _ in nil }
    )

    XCTAssertEqual(result.containers.count, 1)
    if case .pending(let content) = result.containers[0].state,
      case .image = content
    {
      XCTAssertFalse(result.hadError)
    } else {
      XCTFail("Expected pending image content")
    }
  }
}
