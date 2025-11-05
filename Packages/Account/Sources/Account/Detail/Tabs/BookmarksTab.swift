import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

struct BookmarksTab: AccountTabProtocol {
  let id = "bookmarks"
  let iconName = "bookmark"
  let accessibilityLabel: LocalizedStringKey = "accessibility.tabs.profile.picker.bookmarks"
  let isAvailableForCurrentUser = true
  let isAvailableForOtherUsers = false

  func createFetcher(accountId: String, client: MastodonClient, isCurrentUser: Bool) -> any StatusesFetcher
  {
    BookmarksTabFetcher(accountId: accountId, client: client, isCurrentUser: isCurrentUser)
  }

  @ViewBuilder func makeView(
    fetcher: any StatusesFetcher, client: MastodonClient, routerPath: RouterPath, account: Account?
  ) -> some View {
    AnyStatusesListView(
      fetcher: fetcher,
      client: client,
      routerPath: routerPath
    )
  }
}

@MainActor
@Observable
private class BookmarksTabFetcher: AccountTabFetcher {
  private var nextPage: LinkHandler?

  override func fetchNewestStatuses(pullToRefresh: Bool) async {
    do {
      statusesState = .loading
      let result: ([Status], LinkHandler?) = try await client.getWithLink(
        endpoint: Accounts.bookmarks(sinceId: nil)
      )
      statuses = result.0
      nextPage = result.1

      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)
      updateStatusesState(with: statuses, hasMore: nextPage != nil)
    } catch {
      statusesState = .error(error: .noData)
    }
  }

  override func fetchNextPage() async throws {
    guard let nextPageId = nextPage?.maxId else { return }

    let result: ([Status], LinkHandler?) = try await client.getWithLink(
      endpoint: Accounts.bookmarks(sinceId: nextPageId)
    )

    let newStatuses = result.0
    nextPage = result.1

    statuses.append(contentsOf: newStatuses)
    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)
    updateStatusesState(with: statuses, hasMore: nextPage != nil)
  }
}
