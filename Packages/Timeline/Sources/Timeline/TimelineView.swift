import SwiftUI
import Network
import Models
import Shimmer
import Status
import DesignSystem
import Env

public struct TimelineView: View {
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = TimelineViewModel()
  
  private let filter: TimelineFilter?
  
  public init(timeline: TimelineFilter? = nil) {
    self.filter = timeline
  }
  
  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .top) {
        ScrollView {
          LazyVStack {
            tagHeaderView
              .padding(.bottom, 16)
              .id("top")
            StatusesListView(fetcher: viewModel)
          }
          .padding(.top, DS.Constants.layoutPadding)
        }
        if viewModel.timeline == .home {
          makePendingNewPostsView(proxy: proxy)
        }
      }
    }
    .navigationTitle(filter?.title() ?? viewModel.timeline.title())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if client.isAuth {
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
    .onChange(of: watcher.latestEvent?.id) { id in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent, currentAccount: account)
      }
    }
  }
  
  @ViewBuilder
  private func makePendingNewPostsView(proxy: ScrollViewProxy) -> some View {
    if !viewModel.pendingStatuses.isEmpty {
      Button {
        proxy.scrollTo("top")
        viewModel.displayPendingStatuses()
      } label: {
        Text("\(viewModel.pendingStatuses.count) new posts")
      }
      .buttonStyle(.bordered)
      .background(.thinMaterial)
      .cornerRadius(8)
      .padding(.top, 6)
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
