import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

struct BoostsTab: AccountTabProtocol {
  let id = "boosts"
  let iconName = "arrow.2.squarepath"
  let accessibilityLabel: LocalizedStringKey = "accessibility.tabs.profile.picker.boosts"
  let isAvailableForCurrentUser = true
  let isAvailableForOtherUsers = true

  func createFetcher(accountId: String, client: MastodonClient, isCurrentUser: Bool)
    -> any StatusesFetcher
  {
    BoostsTabFetcher(accountId: accountId, client: client, isCurrentUser: isCurrentUser)
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
private class BoostsTabFetcher: AccountTabFetcher {
  var boosts: [Status] = []

  override func fetchNewestStatuses(pullToRefresh: Bool) async {
    do {
      statusesState = .loading
      statuses = try await client.get(
        endpoint: Accounts.statuses(
          id: accountId,
          sinceId: nil,
          tag: nil,
          onlyMedia: false,
          excludeReplies: true,
          excludeReblogs: false,
          pinned: nil
        )
      )

      boosts = statuses.filter { $0.reblog != nil }
      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)
      updateStatusesState(with: boosts, hasMore: statuses.count >= 20)
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
        excludeReplies: true,
        excludeReblogs: false,
        pinned: nil
      )
    )

    statuses.append(contentsOf: newStatuses)
    let newBoosts = newStatuses.filter { $0.reblog != nil }
    boosts.append(contentsOf: newBoosts)

    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)
    updateStatusesState(with: boosts, hasMore: newStatuses.count >= 20)
  }
}
