import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct StatusesListView<Fetcher>: View where Fetcher: StatusesFetcher {
  @Environment(Theme.self) private var theme

  @State private var fetcher: Fetcher
  // Whether this status is on a remote local timeline (many actions are unavailable if so)
  private let isRemote: Bool
  private let routerPath: RouterPath
  private let client: Client

  public init(
    fetcher: Fetcher,
    client: Client,
    routerPath: RouterPath,
    isRemote: Bool = false
  ) {
    _fetcher = .init(initialValue: fetcher)
    self.isRemote = isRemote
    self.client = client
    self.routerPath = routerPath
  }

  public var body: some View {
    switch fetcher.statusesState {
    case .loading:
      ForEach(Status.placeholders()) { status in
        StatusRowView(
          viewModel: .init(status: status, client: client, routerPath: routerPath),
          context: .timeline
        )
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
      }
    case .error:
      ErrorView(
        title: "status.error.title",
        message: "status.error.loading.message",
        buttonTitle: "action.retry"
      ) {
        await fetcher.fetchNewestStatuses(pullToRefresh: false)
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)

    case let .display(statuses, nextPageState):
      ForEach(statuses) { status in
        StatusRowView(
          viewModel: StatusRowViewModel(
            status: status,
            client: client,
            routerPath: routerPath,
            isRemote: isRemote),
          context: .timeline
        )
        .onAppear {
          fetcher.statusDidAppear(status: status)
        }
        .onDisappear {
          fetcher.statusDidDisappear(status: status)
        }
      }
      makeNextPageRow(nextPageState: nextPageState)
      
    case let .displayWithGaps(items, nextPageState):
      ForEach(items) { item in
        switch item {
        case .status(let status):
          StatusRowView(
            viewModel: StatusRowViewModel(
              status: status,
              client: client,
              routerPath: routerPath,
              isRemote: isRemote),
            context: .timeline
          )
          .onAppear {
            fetcher.statusDidAppear(status: status)
          }
          .onDisappear {
            fetcher.statusDidDisappear(status: status)
          }
          
        case .gap(let gap):
          ZStack {
            if let gapLoader = fetcher as? GapLoadingFetcher {
              TimelineGapView(gap: gap) {
                await gapLoader.loadGap(gap: gap)
              }
            }
          }
          .background(theme.primaryBackgroundColor)
          .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
          .listRowSeparator(.hidden)
        }
      }
      makeNextPageRow(nextPageState: nextPageState)
    }
  }
  
  @ViewBuilder
  private func makeNextPageRow(nextPageState: StatusesState.PagingState) -> some View {
    ZStack {
      switch nextPageState {
      case .hasNextPage:
        NextPageView {
          try await fetcher.fetchNextPage()
        }
        .padding(.horizontal, .layoutPadding)

      case .none:
        EmptyView()
      }
    }
    .listRowSeparator(.hidden, edges: .all)
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }
}
