import DesignSystem
import Env
import Models
import Shimmer
import SwiftUI

public struct StatusesListView<Fetcher>: View where Fetcher: StatusesFetcher {
  @EnvironmentObject private var theme: Theme

  @ObservedObject private var fetcher: Fetcher
  private let isRemote: Bool
  private let isEmbdedInList: Bool

  public init(fetcher: Fetcher, isRemote: Bool = false, isEmbdedInList: Bool = true) {
    self.fetcher = fetcher
    self.isRemote = isRemote
    self.isEmbdedInList = isEmbdedInList
  }

  public var body: some View {
    switch fetcher.statusesState {
    case .loading:
      ForEach(Status.placeholders()) { status in
        StatusRowView(viewModel: .init(status: status, isCompact: false))
          .padding(.horizontal, isEmbdedInList ? 0 : .layoutPadding)
          .redacted(reason: .placeholder)
        if !isEmbdedInList {
          Divider()
            .padding(.vertical, .dividerPadding)
        }
      }
    case .error:
      ErrorView(title: "status.error.title",
                message: "status.error.loading.message",
                buttonTitle: "action.retry") {
        Task {
          await fetcher.fetchStatuses()
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)

    case let .display(statuses, nextPageState):
      ForEach(statuses, id: \.viewId) { status in
        let viewModel = StatusRowViewModel(status: status, isCompact: false, isRemote: isRemote)
        if viewModel.filter?.filter.filterAction != .hide {
          StatusRowView(viewModel: viewModel)
            .padding(.horizontal, isEmbdedInList ? 0 : .layoutPadding)
            .id(status.id)
            .onAppear {
              fetcher.statusDidAppear(status: status)
            }
            .onDisappear {
              fetcher.statusDidDisappear(status: status)
            }
          if !isEmbdedInList {
            Divider()
              .padding(.vertical, .dividerPadding)
          }
        }
      }
      switch nextPageState {
      case .hasNextPage:
        loadingRow
          .onAppear {
            Task {
              await fetcher.fetchNextPage()
            }
          }
      case .loadingNextPage:
        loadingRow
      case .none:
        EmptyView()
      }
    }
  }

  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .padding(.horizontal, .layoutPadding)
    .listRowBackground(theme.primaryBackgroundColor)
  }
}
