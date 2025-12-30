import Env
import Models
import NetworkClient
@testable import StatusKit
import XCTest

@MainActor
final class PostingServiceTests: XCTestCase {
  func testBuildStatusDataUsesInputValues() throws {
    let service = StatusEditor.PostingService()
    let input = StatusEditor.PostingService.Input(
      mode: .new(text: nil, visibility: .pub),
      statusText: "Hello",
      visibility: .pub,
      spoilerOn: true,
      spoilerText: "Spoiler",
      mediaAttachments: [makeAttachment(id: "m1")],
      pollOptions: nil,
      pollVotingFrequency: .oneVote,
      pollDuration: .oneDay,
      selectedLanguage: "en",
      pendingMediaAttributes: [
        .init(id: "m1", description: "Alt", thumbnail: nil, focus: nil)
      ],
      embeddedStatusId: "s1",
      allMediaHasDescription: true,
      requiresAltText: false
    )

    let data = try service.buildStatusData(from: input)

    XCTAssertEqual(data.status, "Hello")
    XCTAssertEqual(data.visibility, .pub)
    XCTAssertEqual(data.spoilerText, "Spoiler")
    XCTAssertEqual(data.mediaIds, ["m1"])
    XCTAssertEqual(data.language, "en")
    XCTAssertEqual(data.mediaAttributes?.count, 1)
    XCTAssertEqual(data.quotedStatusId, "s1")
  }

  func testSubmitPostsForNewMode() async throws {
    let service = StatusEditor.PostingService()
    let client = FakePostingClient()
    let input = StatusEditor.PostingService.Input(
      mode: .new(text: nil, visibility: .pub),
      statusText: "Hi",
      visibility: .pub,
      spoilerOn: false,
      spoilerText: "",
      mediaAttachments: [],
      pollOptions: nil,
      pollVotingFrequency: .oneVote,
      pollDuration: .oneDay,
      selectedLanguage: nil,
      pendingMediaAttributes: [],
      embeddedStatusId: nil,
      allMediaHasDescription: true,
      requiresAltText: false
    )

    let status = try await service.submit(input: input, client: client)

    XCTAssertEqual(status.id, "posted")
    XCTAssertEqual(client.postCalls, 1)
    XCTAssertEqual(client.editCalls, 0)
  }

  func testSubmitEditsForEditMode() async throws {
    let service = StatusEditor.PostingService()
    let client = FakePostingClient()
    let status = makeStatus(id: "s1")
    let input = StatusEditor.PostingService.Input(
      mode: .edit(status: status),
      statusText: "Hi",
      visibility: .pub,
      spoilerOn: false,
      spoilerText: "",
      mediaAttachments: [],
      pollOptions: nil,
      pollVotingFrequency: .oneVote,
      pollDuration: .oneDay,
      selectedLanguage: nil,
      pendingMediaAttributes: [],
      embeddedStatusId: nil,
      allMediaHasDescription: true,
      requiresAltText: false
    )

    let result = try await service.submit(input: input, client: client)

    XCTAssertEqual(result.id, "edited")
    XCTAssertEqual(client.postCalls, 0)
    XCTAssertEqual(client.editCalls, 1)
  }
}

@MainActor
private final class FakePostingClient: StatusEditor.PostingService.Client {
  var postCalls = 0
  var editCalls = 0

  func postStatus(data _: StatusData) async throws -> Status {
    postCalls += 1
    return makeStatus(id: "posted")
  }

  func editStatus(id _: String, data _: StatusData) async throws -> Status {
    editCalls += 1
    return makeStatus(id: "edited")
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

private func makeStatus(id: String) -> Status {
  Status(
    id: id,
    content: HTMLString(stringValue: "Hello"),
    account: Account(
      id: "a1",
      username: "user",
      displayName: nil,
      avatar: URL(string: "https://example.com/avatar.png")!,
      header: URL(string: "https://example.com/header.png")!,
      acct: "user",
      note: HTMLString(stringValue: ""),
      createdAt: ServerDate(),
      followersCount: 0,
      followingCount: 0,
      statusesCount: 0,
      fields: [],
      locked: false,
      emojis: [],
      url: URL(string: "https://example.com/@user"),
      source: nil,
      bot: false,
      discoverable: nil,
      moved: nil
    ),
    createdAt: ServerDate(),
    editedAt: nil,
    reblog: nil,
    mediaAttachments: [],
    mentions: [],
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
