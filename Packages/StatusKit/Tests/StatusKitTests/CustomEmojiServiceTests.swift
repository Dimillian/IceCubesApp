import Models
import NetworkClient
@testable import StatusKit
import XCTest

@MainActor
final class CustomEmojiServiceTests: XCTestCase {
  func testBuildCategorizedContainersKeepsCustomLast() {
    let service = StatusEditor.CustomEmojiService()
    let emojis = [
      makeEmoji(shortcode: "a", category: "Z"),
      makeEmoji(shortcode: "b", category: "Custom"),
      makeEmoji(shortcode: "c", category: "A"),
    ]

    let containers = service.buildCategorizedContainers(from: emojis)

    XCTAssertEqual(containers.map(\.categoryName), ["Custom", "A", "Z"])
  }

  func testFetchContainersUsesClient() async throws {
    let service = StatusEditor.CustomEmojiService()
    let client = FakeEmojiClient()
    client.emojis = [makeEmoji(shortcode: "a", category: "Custom")]

    let containers = try await service.fetchContainers(client: client)

    XCTAssertEqual(containers.count, 1)
    XCTAssertEqual(containers.first?.emojis.count, 1)
  }
}

@MainActor
private final class FakeEmojiClient: StatusEditor.CustomEmojiService.Client {
  var emojis: [Emoji] = []

  func fetchCustomEmojis() async throws -> [Emoji] {
    emojis
  }
}

private func makeEmoji(shortcode: String, category: String?) -> Emoji {
  let categoryValue = category.map { "\"\($0)\"" } ?? "null"
  let data = """
  {
    "shortcode": "\(shortcode)",
    "url": "https://example.com/\(shortcode).png",
    "staticUrl": "https://example.com/\(shortcode).png",
    "visibleInPicker": true,
    "category": \(categoryValue)
  }
  """.data(using: .utf8)!
  return try! JSONDecoder().decode(Emoji.self, from: data)
}
