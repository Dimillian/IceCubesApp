import SwiftUI
import Network
import Models
import Shimmer
import Status
import DesignSystem

public struct TimelineView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = TimelineViewModel()
  @State private var didAppear = false
  
  public init() {}
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        StatusesListView(fetcher: viewModel)
      }
      .padding(.top, DS.Constants.layoutPadding)
    }
    .navigationTitle(viewModel.timeline.rawValue)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        timelineFilterButton
      }
    }
    .task {
      viewModel.client = client
      if !didAppear {
        await viewModel.fetchStatuses()
        didAppear = true
      }
    }
    .refreshable {
      await viewModel.fetchStatuses()
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
