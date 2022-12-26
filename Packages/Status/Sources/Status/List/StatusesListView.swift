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
          StatusRowView(viewModel: .init(status: status, isEmbed: false))
            .redacted(reason: .placeholder)
            .shimmering()
          Divider()
            .padding(.vertical, DS.Constants.dividerPadding)
        }
      case let .error(error):
        Text(error.localizedDescription)
      case let .display(statuses, nextPageState):
        ForEach(statuses, id: \.viewId) { status in
          StatusRowView(viewModel: .init(status: status, isEmbed: false))
          Divider()
            .padding(.vertical, DS.Constants.dividerPadding)
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
    .padding(.horizontal, DS.Constants.layoutPadding)
  }
  
  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}
