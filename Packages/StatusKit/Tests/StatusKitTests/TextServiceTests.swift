import Foundation
import Models
@testable import StatusKit
import XCTest

final class TextServiceTests: XCTestCase {
  func testProcessTextSuggestsHashtagAtCursor() {
    let service = StatusEditor.TextService()
    let text = NSMutableAttributedString(string: "Testing #icecubes")
    let selection = NSRange(location: text.string.utf16.count, length: 0)

    let result = service.processText(
      text,
      theme: nil,
      selectedRange: selection,
      hasMarkedText: false,
      previousUrlLengthAdjustments: 0
    )

    XCTAssertTrue(result.didProcess)
    XCTAssertEqual(result.action, .suggest(query: "#icecubes"))
  }

  func testProcessTextResetsSuggestionWhenCursorIsOutsideRange() {
    let service = StatusEditor.TextService()
    let text = NSMutableAttributedString(string: "Testing #icecubes ")
    let selection = NSRange(location: text.string.utf16.count, length: 0)

    let result = service.processText(
      text,
      theme: nil,
      selectedRange: selection,
      hasMarkedText: false,
      previousUrlLengthAdjustments: 0
    )

    XCTAssertTrue(result.didProcess)
    XCTAssertEqual(result.action, .reset)
  }

  func testProcessTextCountsURLLengthAdjustments() {
    let service = StatusEditor.TextService()
    let text = NSMutableAttributedString(
      string: "Check https://example.com and https://example.org"
    )
    let selection = NSRange(location: text.string.utf16.count, length: 0)

    let result = service.processText(
      text,
      theme: nil,
      selectedRange: selection,
      hasMarkedText: false,
      previousUrlLengthAdjustments: 0
    )

    XCTAssertTrue(result.didProcess)
    XCTAssertEqual(result.urlLengthAdjustments, -8)
  }

  func testInitialTextChangesForReplyMentionsAuthorAndMentions() {
    let service = StatusEditor.TextService()
    let author = makeAccount(acct: "alice", username: "alice")
    let mention = Mention(
      id: "mention-1",
      username: "bob",
      url: URL(string: "https://example.com/@bob")!,
      acct: "bob"
    )
    let status = makeStatus(account: author, mentions: [mention])

    let changes = service.initialTextChanges(
      for: .replyTo(status: status),
      currentAccount: makeAccount(acct: "current", username: "current"),
      currentInstance: nil
    )

    XCTAssertEqual(changes.statusText?.string, "@alice @bob ")
    XCTAssertEqual(changes.mentionString, "@alice @bob")
    XCTAssertEqual(changes.selectedRange?.location, "@alice @bob ".utf16.count)
  }
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

private func makeStatus(account: Account, mentions: [Mention]) -> Status {
  Status(
    id: UUID().uuidString,
    content: HTMLString(stringValue: "Hello"),
    account: account,
    createdAt: ServerDate(),
    editedAt: nil,
    reblog: nil,
    mediaAttachments: [],
    mentions: mentions,
    repliesCount: 0,
    reblogsCount: 0,
    favouritesCount: 0,
    card: nil,
    favourited: nil,
    reblogged: nil,
    pinned: nil,
    bookmarked: nil,
    emojis: [],
    url: nil,
    application: nil,
    inReplyToId: nil,
    inReplyToAccountId: nil,
    visibility: .pub,
    poll: nil,
    spoilerText: HTMLString(stringValue: ""),
    filtered: nil,
    sensitive: false,
    language: nil,
    tags: [],
    quote: nil,
    quotesCount: nil,
    quoteApproval: nil
  )
}
