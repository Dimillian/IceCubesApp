import Models
import NetworkClient
import Testing

@testable import Timeline

@MainActor
@Suite("Timeline gap loading", .serialized)
struct TimelineGapLoadingTests {
  /// Timeline: 100, [gap 10…100], 10, 9. Ids are numeric so they sort like Mastodon ids.
  private let gap = TimelineGap(sinceId: "10", maxId: "100")

  private func makeSubject(gapPages: [[Status]]) async -> (
    TimelineViewModel, MockTimelineStatusFetcher
  ) {
    let contentFilter = TimelineContentFilter.shared
    contentFilter.showBoosts = true
    contentFilter.showReplies = true
    contentFilter.showThreads = true
    contentFilter.showQuotePosts = true

    let fetcher = MockTimelineStatusFetcher(firstPage: [], nextPages: [], gapPages: gapPages)
    let subject = TimelineViewModel(statusFetcher: fetcher)
    subject.client = MastodonClient(server: "localhost")
    await subject.reset()
    await subject.datasource.setItems([
      .status(status("100")),
      .gap(gap),
      .status(status("10")),
      .status(status("9")),
    ])
    return (subject, fetcher)
  }

  private func status(_ id: String, hidden: Bool = false) -> Status {
    makeStatus(id: id, hidden: hidden)
  }

  /// Newest first, like the API returns them.
  private func page(_ ids: ClosedRange<Int>) -> [Status] {
    ids.reversed().map { status(String($0)) }
  }

  private func itemIds(_ subject: TimelineViewModel) async -> [String] {
    await subject.datasource.getItems().map(\.id)
  }

  @Test
  func fromOlderFullPageKeepsGapAbove() async throws {
    let (subject, fetcher) = await makeSubject(gapPages: [page(11...50)])

    await subject.loadGap(gap: gap, direction: .fromOlder)

    let calls = await fetcher.gapCalls
    #expect(calls.count == 1)
    #expect(calls.first?.direction == .fromOlder)
    #expect(calls.first?.limit == 40)

    let remaining = TimelineGap(sinceId: "50", maxId: "100")
    let expected = ["100", remaining.id] + (11...50).reversed().map(String.init) + ["10", "9"]
    #expect(await itemIds(subject) == expected)
    // The row under the gap is kept on screen.
    #expect(subject.scrollToId == "10")
    // Loaded posts sit above the reader, so they count as unread.
    #expect(
      subject.pendingStatusesObserver.pendingStatuses == (11...50).reversed().map(String.init))
    // Rows passing by while the list jumps back don't mark posts as read...
    #expect(subject.pendingStatusesObserver.disableUpdate)
    subject.statusDidAppear(status: status("50"))
    #expect(subject.pendingStatusesObserver.pendingStatuses.count == 40)
    subject.statusDidDisappear(status: status("50"))
    // ...but rows still on screen once it settles do.
    subject.statusDidAppear(status: status("12"))
    subject.gapFillScrollDidSettle()
    #expect(!subject.pendingStatusesObserver.disableUpdate)
    #expect(
      subject.pendingStatusesObserver.pendingStatuses == (13...50).reversed().map(String.init))
  }

  @Test
  func fromOlderTapsThroughTheWholeGap() async throws {
    let (subject, _) = await makeSubject(gapPages: [page(11...50), page(51...90), page(91...99)])

    await subject.loadGap(gap: gap, direction: .fromOlder)
    await subject.loadGap(gap: TimelineGap(sinceId: "50", maxId: "100"), direction: .fromOlder)
    #expect(subject.scrollToId == "50")
    await subject.loadGap(gap: TimelineGap(sinceId: "90", maxId: "100"), direction: .fromOlder)

    let expected = ["100"] + (9...99).reversed().map(String.init)
    #expect(await itemIds(subject) == expected)
    #expect(subject.scrollToId == "90")
  }

  @Test
  func fromOlderPartialPageClosesGap() async throws {
    let (subject, _) = await makeSubject(gapPages: [page(11...15)])

    await subject.loadGap(gap: gap, direction: .fromOlder)

    #expect(await itemIds(subject) == ["100", "15", "14", "13", "12", "11", "10", "9"])
    #expect(subject.scrollToId == "10")
  }

  @Test
  func fromOlderAnchorSkipsHiddenStatuses() async throws {
    let (subject, _) = await makeSubject(gapPages: [page(11...12)])
    await subject.datasource.setItems([
      .status(status("100")),
      .gap(gap),
      .status(status("10", hidden: true)),
      .status(status("9")),
    ])

    await subject.loadGap(gap: gap, direction: .fromOlder)

    #expect(subject.scrollToId == "9")
  }

  @Test
  func fromNewerFullPageKeepsGapBelow() async throws {
    let (subject, fetcher) = await makeSubject(gapPages: [page(60...99)])

    await subject.loadGap(gap: gap, direction: .fromNewer)

    #expect(await fetcher.gapCalls.first?.direction == .fromNewer)
    let remaining = TimelineGap(sinceId: "10", maxId: "60")
    let expected = ["100"] + (60...99).reversed().map(String.init) + [remaining.id, "10", "9"]
    #expect(await itemIds(subject) == expected)
    #expect(subject.scrollToId == nil)
    #expect(subject.pendingStatusesObserver.pendingStatuses.isEmpty)
  }

  @Test
  func fromNewerPartialPageClosesGap() async throws {
    let (subject, _) = await makeSubject(gapPages: [page(97...99)])

    await subject.loadGap(gap: gap, direction: .fromNewer)

    #expect(await itemIds(subject) == ["100", "99", "98", "97", "10", "9"])
  }

  @Test
  func openEndedGapAlwaysFillsFromNewer() async throws {
    let openGap = TimelineGap(sinceId: nil, maxId: "9")
    let (subject, fetcher) = await makeSubject(gapPages: [page(1...8)])
    await subject.datasource.setItems([.status(status("10")), .status(status("9")), .gap(openGap)])

    await subject.loadGap(gap: openGap, direction: .fromOlder)

    #expect(await fetcher.gapCalls.first?.direction == .fromNewer)
    #expect(await itemIds(subject) == (1...10).reversed().map(String.init))
    #expect(subject.scrollToId == nil)
  }

  @Test
  func duplicateStatusesAreDropped() async throws {
    let (subject, _) = await makeSubject(gapPages: [[status("12"), status("11"), status("10")]])

    await subject.loadGap(gap: gap, direction: .fromOlder)

    #expect(await itemIds(subject) == ["100", "12", "11", "10", "9"])
  }
}
