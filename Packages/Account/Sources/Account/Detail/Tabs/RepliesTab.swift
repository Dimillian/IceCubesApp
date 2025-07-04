import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

struct RepliesTab: AccountTabProtocol {
  let id = "replies"
  let iconName = "bubble.left.and.bubble.right"
  let accessibilityLabel: LocalizedStringKey = "accessibility.tabs.profile.picker.posts-and-replies"
  let isAvailableForCurrentUser = true
  let isAvailableForOtherUsers = true

  func createFetcher(accountId: String, client: MastodonClient, isCurrentUser: Bool) -> any StatusesFetcher
  {
    RepliesTabFetcher(accountId: accountId, client: client, isCurrentUser: isCurrentUser)
  }

  func makeView(
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
private class RepliesTabFetcher: AccountTabFetcher {
  override func fetchNewestStatuses(pullToRefresh: Bool) async {
    do {
      statusesState = .loading
      statuses = try await client.get(
        endpoint: Accounts.statuses(
          id: accountId,
          sinceId: nil,
          tag: nil,
          onlyMedia: false,
          excludeReplies: false,
          excludeReblogs: true,
          pinned: nil
        )
      )

      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)
      updateStatusesState(with: statuses, hasMore: statuses.count >= 20)
    } catch {
      statusesState = .error(error: .noData)
    }
  }

  override func fetchNextPage() async throws {
    guard let lastId = statuses.last?.id else { return }

    let newStatuses: [Status] = try await client.get(
      endpoint: Accounts.statuses(
        id: accountId,
        sinceId: lastId,
        tag: nil,
        onlyMedia: false,
        excludeReplies: false,
        excludeReblogs: true,
        pinned: nil
      )
    )

    statuses.append(contentsOf: newStatuses)
    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)
    updateStatusesState(with: statuses, hasMore: newStatuses.count >= 20)
  }
}
