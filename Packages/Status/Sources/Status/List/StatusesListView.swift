import SwiftUI
import Models
import Shimmer
import DesignSystem

public struct StatusesListView<Fetcher>: View where Fetcher: StatusesFetcher {
  @ObservedObject private var fetcher: Fetcher
  private let isRemote: Bool
  
  public init(fetcher: Fetcher, isRemote: Bool = false) {
    self.fetcher = fetcher
    self.isRemote = isRemote
  }
  
  public var body: some View {
    Group {
      switch fetcher.statusesState {
      case .loading:
        ForEach(Status.placeholders()) { status in
          StatusRowView(viewModel: .init(status: status, isCompact: false))
            .redacted(reason: .placeholder)
            .shimmering()
            .padding(.horizontal, .layoutPadding)
          Divider()
            .padding(.vertical, .dividerPadding)
        }
      case .error:
        ErrorView(title: "An error occured",
                  message: "An error occured while loading posts, please try again.",
                  buttonTitle: "Retry") {
          Task {
            await fetcher.fetchStatuses()
          }
        }
        
      case let .display(statuses, nextPageState):
        ForEach(statuses, id: \.viewId) { status in
          StatusRowView(viewModel: .init(status: status, isCompact: false, isRemote: isRemote))
            .id(status.id)
            .padding(.horizontal, .layoutPadding)
          Divider()
            .padding(.vertical, .dividerPadding)
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
    .frame(maxWidth: .maxColumnWidth)
  }
  
  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .padding(.horizontal, .layoutPadding)
  }
}
