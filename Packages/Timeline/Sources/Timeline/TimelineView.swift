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
        tagHeaderView
          .padding(.bottom, 16)
        StatusesListView(fetcher: viewModel)
      }
      .padding(.top, DS.Constants.layoutPadding)
    }
    .navigationTitle(filter?.title() ?? viewModel.timeline.title())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if filter == nil, client.isAuth {
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
      await viewModel.fetchStatuses()
    }
  }
  
  @ViewBuilder
  private var tagHeaderView: some View {
    if let tag = viewModel.tag {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("#\(tag.name)")
            .font(.headline)
          Text("\(tag.totalUses) recent posts from \(tag.totalAccounts) participants")
            .font(.footnote)
            .foregroundColor(.gray)
        }
        Spacer()
        Button {
          Task {
            if tag.following {
              await viewModel.unfollowTag(id: tag.name)
            } else {
              await viewModel.followTag(id: tag.name)
            }
          }
        } label: {
          Text(tag.following ? "Following": "Follow")
        }.buttonStyle(.bordered)
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .padding(.vertical, 8)
      .background(.gray.opacity(0.15))
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
