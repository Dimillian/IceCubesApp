import SwiftUI
import Network
import Models
import Shimmer
import Status
import DesignSystem
import Env

public struct TimelineView: View {
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = TimelineViewModel()
  @Binding var timeline: TimelineFilter
  
  public init(timeline: Binding<TimelineFilter>) {
    _timeline = timeline
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
    .navigationTitle(timeline.title())
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      viewModel.client = client
      viewModel.timeline = timeline
    }
    .refreshable {
      Task {
        await viewModel.fetchStatuses(userIntent: true)
      }
    }
    .onChange(of: watcher.latestEvent?.id) { id in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent, currentAccount: account)
      }
    }
    .onChange(of: timeline) { newTimeline in
      viewModel.timeline = timeline
    }
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .active:
        Task {
          await viewModel.fetchStatuses(userIntent: false)
        }
      default:
        break
      }
    })
  }
  
  @ViewBuilder
  private func makePendingNewPostsView(proxy: ScrollViewProxy) -> some View {
    if !viewModel.pendingStatuses.isEmpty {
      Button {
        proxy.scrollTo("top")
        viewModel.displayPendingStatuses()
      } label: {
        Text(viewModel.pendingStatusesButtonTitle)
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
}
