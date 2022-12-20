import SwiftUI
import Network
import Models
import Shimmer
import Status
import DesignSystem

public struct TimelineView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = TimelineViewModel()
  
  private let filter: TimelineFilter?
  
  public init(timeline: TimelineFilter? = nil) {
    self.filter = timeline
  }
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        StatusesListView(fetcher: viewModel)
      }
      .padding(.top, DS.Constants.layoutPadding)
    }
    .navigationTitle(filter?.title() ?? viewModel.timeline.title())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if filter == nil {
        ToolbarItem(placement: .navigationBarTrailing) {
          timelineFilterButton
        }
      }
    }
    .onAppear {
      viewModel.client = client
      if let filter {
        viewModel.timeline = filter
      } else {
        viewModel.timeline = client.isAuth ? .home : .pub
      }
    }
    .refreshable {
      Task {
        await viewModel.fetchStatuses()
      }
    }
  }
  
  
  private var timelineFilterButton: some View {
    Menu {
      ForEach(TimelineFilter.availableTimeline(), id: \.self) { filter in
        Button {
          viewModel.timeline = filter
        } label: {
          Text(filter.title())
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal.decrease.circle")
    }

  }
}
