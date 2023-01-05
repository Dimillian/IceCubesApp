import SwiftUI
import Models
import Shimmer
import DesignSystem

public struct StatusesListView<Fetcher>: View where Fetcher: StatusesFetcher {
  @ObservedObject private var fetcher: Fetcher
  
  public init(fetcher: Fetcher) {
    self.fetcher = fetcher
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
      case let .error(error):
        Text(error.localizedDescription)
      case let .display(statuses, nextPageState):
        ForEach(statuses, id: \.viewId) { status in
          StatusRowView(viewModel: .init(status: status, isCompact: false))
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
