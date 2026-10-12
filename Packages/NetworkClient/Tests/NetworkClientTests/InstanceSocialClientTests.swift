import Foundation
import Models
import XCTest

@testable import NetworkClient

final class InstanceSocialClientTests: XCTestCase {
  func testSuggestionsExcludeTrailingDotAliases() throws {
    let instances = try decodeInstances()

    XCTAssertEqual(
      instances.suggestions(matching: "").map(\.name),
      ["mastodon.social", "example.social"]
    )
  }

  func testSearchExcludesTrailingDotAliasesAndPrioritizesMatches() throws {
    let instances = try decodeInstances()

    XCTAssertEqual(
      instances.suggestions(matching: " example ").map(\.name),
      ["example.social", "mastodon.social"]
    )
    XCTAssertEqual(
      instances.suggestions(matching: "mastodon.social").map(\.name),
      ["mastodon.social", "example.social"]
    )
  }

  func testSuggestionsCanBeEmpty() throws {
    let instances = try decodeInstances().filter { $0.name.hasSuffix(".") }

    XCTAssertTrue(instances.suggestions(matching: "").isEmpty)
    XCTAssertTrue([InstanceSocial]().suggestions(matching: "mastodon").isEmpty)
  }

  private func decodeInstances() throws -> [InstanceSocial] {
    let data = Data(
      """
      {"instances": [
        {"id": "alias", "name": "mastodon.social.", "dead": false,
         "users": "3429288", "statuses": "191464673"},
        {"id": "canonical", "name": "mastodon.social", "dead": false,
         "users": "3429280", "statuses": "191463818"},
        {"id": "other", "name": "example.social", "dead": false,
         "users": "1000", "statuses": "2000"}
      ]}
      """.utf8)
    return try JSONDecoder().decode(InstanceSocialClient.Response.self, from: data).instances
  }
}
