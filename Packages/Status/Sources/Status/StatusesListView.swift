import SwiftUI
import Models
import Shimmer
import DesignSystem

public enum StatusesState {
  public enum PagingState {
    case hasNextPage, loadingNextPage
  }
  case loading
  case display(statuses: [Status], nextPageState: StatusesState.PagingState)
  case error(error: Error)
}

@MainActor
public protocol StatusesFetcher: ObservableObject {
  var statusesState: StatusesState { get }
  func fetchStatuses() async
  func fetchNextPage() async
}

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
          StatusRowView(status: status)
            .redacted(reason: .placeholder)
            .shimmering()
          Divider()
            .padding(.bottom, DS.Constants.layoutPadding)
        }
      case let .error(error):
        Text(error.localizedDescription)
      case let .display(statuses, nextPageState):
        ForEach(statuses) { status in
          StatusRowView(status: status)
          Divider()
            .padding(.bottom, DS.Constants.layoutPadding)
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
        }
      }
    }
    .padding(.horizontal, 16)
  }
  
  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}
