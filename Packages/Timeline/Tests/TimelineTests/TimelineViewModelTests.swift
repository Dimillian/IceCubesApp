import Models
import NetworkClient
import Testing
import XCTest

@testable import Timeline

@MainActor
@Suite("Timeline View Model tests")
struct Tests {
  func makeSubject() -> TimelineViewModel {
    let subject = TimelineViewModel()
    let client = MastodonClient(server: "localhost")
    subject.client = client
    subject.timeline = .home
    subject.timelineTask?.cancel()
    return subject
  }

  /*
  @Test
  func streamEventInsertNewStatus() async throws {
    let subject = makeSubject()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    await subject.datasource.append(.placeholder())
    var count = await subject.datasource.count()
    #expect(count == 1)
    await subject.handleEvent(event: StreamEventUpdate(status: .placeholder()))
    count = await subject.datasource.count()
    #expect(count == 2)
  }
   */

  @Test
  func streamEventInsertDuplicateStatus() async throws {
    let subject = makeSubject()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    let status = Status.placeholder()
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    #expect(count == 1)
    await subject.handleEvent(event: StreamEventUpdate(status: status))
    count = await subject.datasource.count()
    #expect(count == 1)
  }

  @Test
  func streamEventRemove() async throws {
    let subject = makeSubject()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    let status = Status.placeholder()
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    #expect(count == 1)
    await subject.handleEvent(event: StreamEventDelete(status: status.id))
    count = await subject.datasource.count()
    #expect(count == 0)
  }

  @Test
  func streamEventUpdateStatus() async throws {
    let subject = makeSubject()
    var status = Status.placeholder()
    let isEmpty = await subject.datasource.isEmpty
    #expect(isEmpty)
    await subject.datasource.append(status)
    var count = await subject.datasource.count()
    #expect(count == 1)
    status = .init(
      id: status.id,
      content: .init(stringValue: "test"),
      account: status.account,
      createdAt: status.createdAt,
      editedAt: status.editedAt,
      reblog: status.reblog,
      mediaAttachments: status.mediaAttachments,
      mentions: status.mentions,
      repliesCount: status.repliesCount,
      reblogsCount: status.reblogsCount,
      favouritesCount: status.favouritesCount,
      card: status.card,
      favourited: status.favourited,
      reblogged: status.reblogged,
      pinned: status.pinned,
      bookmarked: status.bookmarked,
      emojis: status.emojis,
      url: status.url,
      application: status.application,
      inReplyToId: status.inReplyToId,
      inReplyToAccountId: status.inReplyToAccountId,
      visibility: status.visibility,
      poll: status.poll,
      spoilerText: status.spoilerText,
      filtered: status.filtered,
      sensitive: status.sensitive,
      language: status.language,
      quote: nil,
      quotesCount: nil,
      quoteApproval: nil)
    await subject.handleEvent(event: StreamEventStatusUpdate(status: status))
    let statuses = await subject.datasource.get()
    count = await subject.datasource.count()
    #expect(count == 1)
    #expect(statuses.first?.content.asRawText == "test")
  }

  @Test
  func autoFetchesWhenFilteredStatusesAreEmpty() async throws {
    let contentFilter = TimelineContentFilter.shared
    contentFilter.showBoosts = true
    contentFilter.showReplies = true
    contentFilter.showThreads = true
    contentFilter.showQuotePosts = true

    let hiddenFirstPage = (0..<50).map { makeStatus(id: "hidden-first-\($0)", hidden: true) }
    let hiddenSecondPage = (0..<40).map { makeStatus(id: "hidden-next-\($0)", hidden: true) }
    let visibleThirdPage = [makeStatus(id: "visible-0", hidden: false)]

    let fetcher = MockTimelineStatusFetcher(
      firstPage: hiddenFirstPage,
      nextPages: [hiddenSecondPage, visibleThirdPage])

    let subject = TimelineViewModel(statusFetcher: fetcher)
    subject.client = MastodonClient(server: "localhost")
    await subject.reset()

    await subject.fetchNewestStatuses(pullToRefresh: false)

    let filteredItems = await subject.datasource.getFilteredItems()
    #expect(!filteredItems.isEmpty)
    #expect(await fetcher.nextPageCallCount() >= 2)
  }

  @Test
  func hideQuotePostsFiltersLegacyAndNativeQuotes() async throws {
    let normalStatus = makeStatus(id: "normal", hidden: false)
    let legacyQuoteStatus = makeStatus(
      id: "legacy-quote",
      content: try makeHTMLStringWithStatusLink(),
      quote: nil
    )
    let nativeQuoteStatus = makeStatus(
      id: "native-quote",
      content: Status.placeholder().content,
      quote: try makeQuote(quotedStatusId: "123")
    )

    let datasource = TimelineDatasource()
    await datasource.set([normalStatus, legacyQuoteStatus, nativeQuoteStatus])

    let snapshot = TimelineContentFilter.Snapshot(
      showBoosts: true,
      showReplies: true,
      showThreads: true,
      showQuotePosts: false,
      hidePostsWithMedia: false,
      hidePostsFromBots: false
    )
    let filtered = await datasource.getFiltered(using: snapshot)
    #expect(filtered.map(\.id) == ["normal"])
  }

  @Test
  func hidePostsFromBotsUsesOriginalAuthorForBoosts() async throws {
    let boostedBotByHuman = makeBoostStatus(
      id: "boosted-bot-by-human",
      boosterIsBot: false,
      originalAuthorIsBot: true
    )
    let boostedHumanByBot = makeBoostStatus(
      id: "boosted-human-by-bot",
      boosterIsBot: true,
      originalAuthorIsBot: false
    )
    let regularHuman = makeStatus(id: "regular-human", hidden: false)

    let datasource = TimelineDatasource()
    await datasource.set([boostedBotByHuman, boostedHumanByBot, regularHuman])

    let snapshot = TimelineContentFilter.Snapshot(
      showBoosts: true,
      showReplies: true,
      showThreads: true,
      showQuotePosts: true,
      hidePostsWithMedia: false,
      hidePostsFromBots: true
    )
    let filtered = await datasource.getFiltered(using: snapshot)

    #expect(filtered.map(\.id) == ["boosted-human-by-bot", "regular-human"])
  }
}

private func makeHTMLStringWithStatusLink() throws -> HTMLString {
  let html =
    "\"<p>Quoted <a href=\\\"https://example.com/@bob/123\\\">link</a></p>\""
  return try JSONDecoder().decode(HTMLString.self, from: Data(html.utf8))
}

private func makeBoostStatus(
  id: String,
  boosterIsBot: Bool,
  originalAuthorIsBot: Bool
) -> Status {
  let base = Status.placeholder()
  let boosterAccount = makeAccount(from: base.account, id: "\(id)-booster", bot: boosterIsBot)
  let originalAccount = makeAccount(from: base.account, id: "\(id)-original", bot: originalAuthorIsBot)

  let reblog = ReblogStatus(
    id: "\(id)-reblog",
    content: base.content,
    account: originalAccount,
    createdAt: base.createdAt,
    editedAt: base.editedAt,
    mediaAttachments: base.mediaAttachments,
    mentions: base.mentions,
    repliesCount: base.repliesCount,
    reblogsCount: base.reblogsCount,
    favouritesCount: base.favouritesCount,
    card: base.card,
    favourited: base.favourited,
    reblogged: base.reblogged,
    pinned: base.pinned,
    bookmarked: base.bookmarked,
    emojis: base.emojis,
    url: base.url,
    application: base.application,
    inReplyToId: base.inReplyToId,
    inReplyToAccountId: base.inReplyToAccountId,
    visibility: base.visibility,
    poll: base.poll,
    spoilerText: base.spoilerText,
    filtered: base.filtered,
    sensitive: base.sensitive,
    language: base.language,
    tags: base.tags,
    quote: base.quote,
    quotesCount: base.quotesCount,
    quoteApproval: base.quoteApproval
  )

  return Status(
    id: id,
    content: base.content,
    account: boosterAccount,
    createdAt: base.createdAt,
    editedAt: base.editedAt,
    reblog: reblog,
    mediaAttachments: base.mediaAttachments,
    mentions: base.mentions,
    repliesCount: base.repliesCount,
    reblogsCount: base.reblogsCount,
    favouritesCount: base.favouritesCount,
    card: base.card,
    favourited: base.favourited,
    reblogged: base.reblogged,
    pinned: base.pinned,
    bookmarked: base.bookmarked,
    emojis: base.emojis,
    url: base.url,
    application: base.application,
    inReplyToId: base.inReplyToId,
    inReplyToAccountId: base.inReplyToAccountId,
    visibility: base.visibility,
    poll: base.poll,
    spoilerText: base.spoilerText,
    filtered: base.filtered,
    sensitive: base.sensitive,
    language: base.language,
    tags: base.tags,
    quote: base.quote,
    quotesCount: base.quotesCount,
    quoteApproval: base.quoteApproval
  )
}

private func makeAccount(from base: Account, id: String, bot: Bool) -> Account {
  Account(
    id: id,
    username: "\(base.username)-\(id)",
    displayName: base.displayName,
    avatar: base.avatar,
    header: base.header,
    acct: "\(base.acct)-\(id)",
    note: base.note,
    createdAt: base.createdAt,
    followersCount: base.followersCount ?? 0,
    followingCount: base.followingCount ?? 0,
    statusesCount: base.statusesCount ?? 0,
    lastStatusAt: base.lastStatusAt,
    fields: base.fields,
    locked: base.locked,
    emojis: base.emojis,
    url: base.url,
    source: base.source,
    bot: bot,
    discoverable: base.discoverable,
    moved: nil
  )
}
