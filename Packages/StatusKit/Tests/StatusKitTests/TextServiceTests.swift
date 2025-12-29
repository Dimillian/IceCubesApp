import Foundation
import Models
@testable import StatusKit
import UniformTypeIdentifiers
import XCTest

@MainActor
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

  func testProcessTextResetsSuggestionWhenCursorIsInsideHashtag() {
    let service = StatusEditor.TextService()
    let text = NSMutableAttributedString(string: "Testing #icecubes")
    let selection = NSRange(location: "Testing #ice".utf16.count, length: 0)

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

  func testProcessTextSuggestsHashtagWithEmojiPrefix() {
    let service = StatusEditor.TextService()
    let text = NSMutableAttributedString(string: "Hello 😄 #icecubes")
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

  func testInitialTextChangesForEditNormalizesMentionAcct() {
    let service = StatusEditor.TextService()
    let author = makeAccount(acct: "alice", username: "alice")
    let mention = Mention(
      id: "mention-1",
      username: "bob",
      url: URL(string: "https://example.com/@bob")!,
      acct: "bob@server"
    )
    let status = makeStatus(
      account: author,
      mentions: [mention],
      content: HTMLString(stringValue: "Hello @bob")
    )

    let changes = service.initialTextChanges(
      for: .edit(status: status),
      currentAccount: nil,
      currentInstance: nil
    )

    XCTAssertEqual(changes.statusText?.string, "Hello @bob@server")
  }

  func testInitialTextChangesForLegacyQuoteIncludesAuthorAndURL() {
    let service = StatusEditor.TextService()
    let author = makeAccount(acct: "alice", username: "alice")
    let status = makeStatus(
      account: author,
      mentions: [],
      url: URL(string: "https://example.com/@alice/1")
    )

    let changes = service.initialTextChanges(
      for: .quote(status: status),
      currentAccount: nil,
      currentInstance: nil
    )

    XCTAssertEqual(
      changes.statusText?.string,
      "\n\nFrom: @alice\nhttps://example.com/@alice/1"
    )
  }

  func testShareExtensionTextItemsInsertLeadingText() async {
    let item = NSItemProvider(
      item: "Hello" as NSString,
      typeIdentifier: UTType.plainText.identifier
    )
    let viewModel = await MainActor.run {
      StatusEditor.ViewModel(mode: .shareExtension(items: [item]))
    }

    await MainActor.run {
      viewModel.prepareStatusText()
    }

    let expectation = XCTestExpectation(description: "Wait for share text")
    Task {
      for _ in 0..<20 {
        let text = await MainActor.run { viewModel.statusText.string }
        if text == "\n\nHello " {
          expectation.fulfill()
          return
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
      }
    }
    await fulfillment(of: [expectation], timeout: 3.0)
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

private func makeStatus(
  account: Account,
  mentions: [Mention],
  content: HTMLString = HTMLString(stringValue: "Hello"),
  url: URL? = nil
) -> Status {
  Status(
    id: UUID().uuidString,
    content: content,
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
    url: url?.absoluteString,
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
