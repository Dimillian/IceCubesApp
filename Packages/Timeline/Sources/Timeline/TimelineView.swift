import SwiftUI
import Network

public struct TimelineView: View {
  @StateObject private var viewModel: TimelineViewModel
  @State private var didAppear = false
  
  public init(client: Client) {
    _viewModel = StateObject(wrappedValue: TimelineViewModel(client: client))
  }
  
  public var body: some View {
    List {
      switch viewModel.state {
      case .loading:
        loadingRow
      case let .error(error):
        Text(error.localizedDescription)
      case let .display(statuses, nextPageState):
        ForEach(statuses) { status in
          StatusRowView(status: status)
        }
        switch nextPageState {
        case .hasNextPage:
          loadingRow
            .onAppear {
              Task {
                await viewModel.loadNextPage()
              }
            }
        case .loadingNextPage:
          loadingRow
        }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Public Timeline: \(viewModel.serverName)")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if !didAppear {
        await viewModel.refreshTimeline()
        didAppear = true
      }
    }
    .refreshable {
      await viewModel.refreshTimeline()
    }
  }
  
  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}
