import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

struct MediaTab: AccountTabProtocol {
  let id = "media"
  let iconName = "photo.on.rectangle.angled"
  let accessibilityLabel: LocalizedStringKey = "accessibility.tabs.profile.picker.media"
  let isAvailableForCurrentUser = false
  let isAvailableForOtherUsers = true

  func createFetcher(accountId: String, client: MastodonClient, isCurrentUser: Bool) -> any StatusesFetcher
  {
    MediaTabFetcher(accountId: accountId, client: client, isCurrentUser: isCurrentUser)
  }

  func makeView(
    fetcher: any StatusesFetcher, client: MastodonClient, routerPath: RouterPath, account: Account?
  ) -> some View {
    MediaTabView(
      fetcher: fetcher as! MediaTabFetcher, client: client, routerPath: routerPath, account: account
    )
  }
}

@MainActor
@Observable
private class MediaTabFetcher: AccountTabFetcher {
  var statusesMedias: [MediaStatus] {
    statuses.filter { !$0.mediaAttachments.isEmpty }.flatMap { $0.asMediaStatus }
  }

  override func fetchNewestStatuses(pullToRefresh: Bool) async {
    do {
      statusesState = .loading
      statuses = try await client.get(
        endpoint: Accounts.statuses(
          id: accountId,
          sinceId: nil,
          tag: nil,
          onlyMedia: true,
          excludeReplies: true,
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
        onlyMedia: true,
        excludeReplies: true,
        excludeReblogs: true,
        pinned: nil
      )
    )

    statuses.append(contentsOf: newStatuses)
    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)
    updateStatusesState(with: statuses, hasMore: newStatuses.count >= 20)
  }
}

private struct MediaTabView: View {
  let fetcher: MediaTabFetcher
  let client: MastodonClient
  let routerPath: RouterPath
  let account: Account?

  @Environment(Theme.self) private var theme

  var body: some View {
    Group {
      HStack {
        Label("Media Grid", systemImage: "square.grid.2x2")
        Spacer()
        Image(systemName: "chevron.right")
      }
      .onTapGesture {
        if let account {
          routerPath.navigate(
            to: .accountMediaGridView(
              account: account,
              initialMediaStatuses: fetcher.statusesMedias
            )
          )
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      AnyStatusesListView(
        fetcher: fetcher,
        client: client,
        routerPath: routerPath
      )
    }
  }
}
