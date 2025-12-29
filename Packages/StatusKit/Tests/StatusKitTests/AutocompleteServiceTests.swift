import Foundation
import Models
@testable import StatusKit
import XCTest

@MainActor
final class AutocompleteServiceTests: XCTestCase {
  func testHashtagQuerySingleCharacterShowsRecents() async throws {
    let client = FakeAutocompleteClient()
    let service = StatusEditor.AutocompleteService()

    let result = try await service.fetchSuggestions(for: "#", client: client)

    XCTAssertEqual(result, .showRecentsTagsInline)
    XCTAssertEqual(client.hashtagsCalls, 0)
    XCTAssertEqual(client.accountsCalls, 0)
  }

  func testHashtagQuerySortsByTotalUses() async throws {
    let client = FakeAutocompleteClient()
    client.hashtags = [
      makeTag(name: "low", uses: "2"),
      makeTag(name: "high", uses: "10"),
    ]
    let service = StatusEditor.AutocompleteService()

    let result = try await service.fetchSuggestions(for: "#ice", client: client)

    XCTAssertEqual(result, .tags([makeTag(name: "high", uses: "10"), makeTag(name: "low", uses: "2")]))
    XCTAssertEqual(client.hashtagsCalls, 1)
    XCTAssertEqual(client.accountsCalls, 0)
  }

  func testMentionQueryFetchesAccounts() async throws {
    let client = FakeAutocompleteClient()
    client.accounts = [
      makeAccount(acct: "alice", username: "alice"),
      makeAccount(acct: "bob", username: "bob"),
    ]
    let service = StatusEditor.AutocompleteService()

    let result = try await service.fetchSuggestions(for: "@al", client: client)

    XCTAssertEqual(result, .mentions(client.accounts))
    XCTAssertEqual(client.hashtagsCalls, 0)
    XCTAssertEqual(client.accountsCalls, 1)
  }

  func testMentionQuerySingleCharacterReturnsNone() async throws {
    let client = FakeAutocompleteClient()
    let service = StatusEditor.AutocompleteService()

    let result = try await service.fetchSuggestions(for: "@", client: client)

    XCTAssertEqual(result, .none)
    XCTAssertEqual(client.hashtagsCalls, 0)
    XCTAssertEqual(client.accountsCalls, 0)
  }

  func testNonTriggerQueryReturnsNone() async throws {
    let client = FakeAutocompleteClient()
    let service = StatusEditor.AutocompleteService()

    let result = try await service.fetchSuggestions(for: "hello", client: client)

    XCTAssertEqual(result, .none)
    XCTAssertEqual(client.hashtagsCalls, 0)
    XCTAssertEqual(client.accountsCalls, 0)
  }
}

@MainActor
private final class FakeAutocompleteClient: StatusEditor.AutocompleteService.Client {
  var hashtagsCalls = 0
  var accountsCalls = 0
  var hashtags: [Tag] = []
  var accounts: [Account] = []

  func searchHashtags(query _: String) async throws -> [Tag] {
    hashtagsCalls += 1
    return hashtags
  }

  func searchAccounts(query _: String) async throws -> [Account] {
    accountsCalls += 1
    return accounts
  }
}

private func makeTag(name: String, uses: String) -> Tag {
  let data = """
  {
    "name": "\(name)",
    "url": "https://example.com/tags/\(name)",
    "following": false,
    "history": [
      {
        "day": "1",
        "accounts": "0",
        "uses": "\(uses)"
      }
    ]
  }
  """.data(using: .utf8)!
  return try! JSONDecoder().decode(Tag.self, from: data)
}

private func makeAccount(acct: String, username: String) -> Account {
  Account(
    id: UUID().uuidString,
    username: username,
    displayName: nil,
    avatar: URL(string: "https://example.com/avatar.png")!,
    header: URL(string: "https://example.com/header.png")!,
    acct: acct,
    note: HTMLString(stringValue: ""),
    createdAt: ServerDate(),
    followersCount: 0,
    followingCount: 0,
    statusesCount: 0,
    fields: [],
    locked: false,
    emojis: [],
    url: URL(string: "https://example.com/@\(acct)"),
    source: nil,
    bot: false,
    discoverable: nil,
    moved: nil
  )
}
