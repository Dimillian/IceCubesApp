import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

struct StatusesTab: AccountTabProtocol {
  let id = "statuses"
  let iconName = "bubble.right"
  let accessibilityLabel: LocalizedStringKey = "accessibility.tabs.profile.picker.statuses"
  let isAvailableForCurrentUser = true
  let isAvailableForOtherUsers = true

  func createFetcher(accountId: String, client: MastodonClient, isCurrentUser: Bool) -> any StatusesFetcher
  {
    StatusesTabFetcher(accountId: accountId, client: client, isCurrentUser: isCurrentUser)
  }

  func makeView(
    fetcher: any StatusesFetcher, client: MastodonClient, routerPath: RouterPath, account: Account?
  ) -> some View {
    StatusesTabView(
      fetcher: fetcher as! StatusesTabFetcher, client: client, routerPath: routerPath)
  }
}

@MainActor
@Observable
private class StatusesTabFetcher: AccountTabFetcher {
  var pinned: [Status] = []

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
          excludeReblogs: true,
          pinned: nil
        )
      )

      pinned = try await client.get(
        endpoint: Accounts.statuses(
          id: accountId,
          sinceId: nil,
          tag: nil,
          onlyMedia: false,
          excludeReplies: false,
          excludeReblogs: false,
          pinned: true
        )
      )

      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)
      StatusDataControllerProvider.shared.updateDataControllers(for: pinned, client: client)

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
        excludeReplies: true,
        excludeReblogs: true,
        pinned: nil
      )
    )

    statuses.append(contentsOf: newStatuses)
    StatusDataControllerProvider.shared.updateDataControllers(for: newStatuses, client: client)
    updateStatusesState(with: statuses, hasMore: newStatuses.count >= 20)
  }

  override func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    // Handle pinned posts updates in addition to the base implementation
    super.handleEvent(event: event, currentAccount: currentAccount)

    if let event = event as? StreamEventDelete {
      pinned.removeAll(where: { $0.id == event.status })
    } else if let event = event as? StreamEventStatusUpdate {
      if let pinnedIndex = pinned.firstIndex(where: { $0.id == event.status.id }) {
        pinned[pinnedIndex] = event.status
      }
    }
  }
}

private struct StatusesTabView: View {
  let fetcher: StatusesTabFetcher
  let client: MastodonClient
  let routerPath: RouterPath

  @Environment(Theme.self) private var theme

  var body: some View {
    Group {
      if !fetcher.pinned.isEmpty {
        pinnedPostsView
      }

      AnyStatusesListView(
        fetcher: fetcher,
        client: client,
        routerPath: routerPath
      )
    }
  }

  @ViewBuilder
  private var pinnedPostsView: some View {
    Label("account.post.pinned", systemImage: "pin.fill")
      .accessibilityAddTraits(.isHeader)
      .font(.scaledFootnote)
      .foregroundStyle(.secondary)
      .fontWeight(.semibold)
      .listRowInsets(
        .init(
          top: 0,
          leading: 12,
          bottom: 0,
          trailing: .layoutPadding)
      )
      .listRowSeparator(.hidden)
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

    ForEach(fetcher.pinned) { status in
      StatusRowExternalView(
        viewModel: .init(status: status, client: client, routerPath: routerPath)
      )
    }

    Rectangle()
      #if os(visionOS)
        .fill(Color.clear)
      #else
        .fill(theme.secondaryBackgroundColor)
      #endif
      .frame(height: 12)
      .listRowInsets(.init())
      .listRowSeparator(.hidden)
      .accessibilityHidden(true)
  }
}
