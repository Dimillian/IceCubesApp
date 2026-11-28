// Debug builds only: tools to create timeline gaps on demand, so gap loading can be tested
// without waiting for a real gap (quit, let 40+ posts arrive, relaunch).
#if DEBUG
  import Env
  import Models
  import NetworkClient
  import StatusKit
  import SwiftUI

  extension TimelineViewModel {
    /// Replaces `size` real posts below the first `keepTop` posts with a gap whose bounds are the
    /// posts on either side, so "Load more" refetches them from the server. Loads older pages
    /// first if fewer posts are loaded. Existing gaps are dropped.
    func debugInsertGap(keepTop: Int = 5, size: Int, scrollBelowGap: Bool) async {
      guard let client else { return }
      var statuses = await datasource.get()
      while statuses.count < keepTop + size + 1, let last = statuses.last {
        guard
          let next: [Status] = try? await client.get(
            endpoint: timeline.endpoint(
              sinceId: nil, maxId: last.id, minId: nil, offset: statuses.count, limit: 40)),
          !next.isEmpty
        else { break }
        StatusDataControllerProvider.shared.updateDataControllers(for: next, client: client)
        await datasource.append(contentOf: next)
        statuses = await datasource.get()
      }
      guard statuses.count > keepTop + 1 else { return }

      let size = min(size, statuses.count - keepTop - 1)
      let below = statuses[keepTop + size]
      let gap = TimelineGap(sinceId: below.id, maxId: statuses[keepTop - 1].id)
      let items: [TimelineItem] =
        statuses[..<keepTop].map { .status($0) } + [.gap(gap)]
        + statuses[(keepTop + size)...].map { .status($0) }
      await datasource.setItems(items)

      // Set the state and the scroll target together, so the target row exists when scrolling.
      let filtered = await datasource.getFilteredItems()
      if scrollBelowGap {
        scrollToId = below.id
      }
      statusesState = .displayWithGaps(items: filtered, nextPageState: .hasNextPage)
    }
  }

  /// Toolbar menu that inserts a test gap into the current timeline.
  struct TimelineDebugGapMenu: View {
    let viewModel: TimelineViewModel

    var body: some View {
      Menu {
        Section("Insert test gap") {
          Button("120 posts, scroll below it (read old → new)") {
            Task { await viewModel.debugInsertGap(size: 120, scrollBelowGap: true) }
          }
          Button("120 posts, stay above it (read new → old)") {
            Task { await viewModel.debugInsertGap(size: 120, scrollBelowGap: false) }
          }
          Button("10 posts, scroll below it (fills in one tap)") {
            Task { await viewModel.debugInsertGap(size: 10, scrollBelowGap: true) }
          }
        }
      } label: {
        Image(systemName: "ladybug")
      }
      .accessibilityLabel("Debug: insert test gap")
    }
  }
#endif
