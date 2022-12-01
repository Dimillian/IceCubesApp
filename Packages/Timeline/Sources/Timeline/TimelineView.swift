import SwiftUI
import Network

public struct TimelineView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = TimelineViewModel()
  @State private var didAppear = false
  
  public init() {}
  
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
    .navigationTitle("\(viewModel.serverName)")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        timelineFilterButton
      }
    }
    .task {
      viewModel.client = client
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
  
  private var timelineFilterButton: some View {
    Menu {
      ForEach(TimelineViewModel.TimelineFilter.allCases, id: \.self) { filter in
        Button {
          viewModel.timeline = filter
        } label: {
          Text(filter.rawValue)
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal.decrease.circle")
    }

  }
}
