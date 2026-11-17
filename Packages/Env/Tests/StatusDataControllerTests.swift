import Models
import NetworkClient
import Testing

@testable import Env

@MainActor
private func makeStatus(id: String, text: String) -> Status {
  .init(
    id: id,
    content: .init(stringValue: text),
    account: .placeholder(),
    createdAt: ServerDate(),
    editedAt: nil,
    reblog: nil,
    mediaAttachments: [],
    mentions: [],
    repliesCount: 0,
    reblogsCount: 0,
    favouritesCount: 0,
    card: nil,
    favourited: false,
    reblogged: false,
    pinned: false,
    bookmarked: false,
    emojis: [],
    url: nil,
    application: nil,
    inReplyToId: nil,
    inReplyToAccountId: nil,
    visibility: .pub,
    poll: nil,
    spoilerText: .init(stringValue: ""),
    filtered: [],
    sensitive: false,
    language: nil,
    quote: nil,
    quotesCount: nil,
    quoteApproval: nil)
}

@Test
@MainActor
func testStatusDataControllerKeepsLatestEdit() {
  let client = MastodonClient(server: "mastodon.social")
  let controller = StatusDataController(status: makeStatus(id: "1", text: "first"), client: client)

  controller.updateFrom(status: makeStatus(id: "1", text: "second"))

  #expect(controller.status.content.asRawText == "second")
  #expect(controller.content.asRawText == "second")
}

@Test
@MainActor
func testStatusDataControllerIgnoresStatusWithAnotherId() {
  let client = MastodonClient(server: "mastodon.social")
  let controller = StatusDataController(status: makeStatus(id: "1", text: "first"), client: client)

  controller.updateFrom(status: makeStatus(id: "remote", text: "remote copy"))

  #expect(controller.status.id == "1")
  #expect(controller.status.content.asRawText == "first")
}
