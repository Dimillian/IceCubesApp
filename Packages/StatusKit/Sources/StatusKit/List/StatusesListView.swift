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

  public init(fetcher: Fetcher,
              client: Client,
              routerPath: RouterPath,
              isRemote: Bool = false)
  {
    _fetcher = .init(initialValue: fetcher)
    self.isRemote = isRemote
    self.client = client
    self.routerPath = routerPath
  }

  public var body: some View {
    switch fetcher.statusesState {
    case .loading:
      ForEach(Status.placeholders()) { status in
        StatusRowView(viewModel: .init(status: status, client: client, routerPath: routerPath))
          .redacted(reason: .placeholder)
          .allowsHitTesting(false)
      }
    case .error:
      ErrorView(title: "status.error.title",
                message: "status.error.loading.message",
                buttonTitle: "action.retry")
      {
        await fetcher.fetchNewestStatuses(pullToRefresh: false)
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)

    case let .display(statuses, nextPageState):
      ForEach(statuses, id: \.id) { status in
        StatusRowView(viewModel: StatusRowViewModel(status: status,
                                                    client: client,
                                                    routerPath: routerPath,
                                                    isRemote: isRemote))
          .onAppear {
            fetcher.statusDidAppear(status: status)
          }
          .onDisappear {
            fetcher.statusDidDisappear(status: status)
          }
      }
      switch nextPageState {
      case .hasNextPage:
        NextPageView {
          try await fetcher.fetchNextPage()
        }
        .padding(.horizontal, .layoutPadding)
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #endif

      case .none:
        EmptyView()
      }
    }
  }
}
