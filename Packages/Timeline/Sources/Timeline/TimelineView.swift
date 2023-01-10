import SwiftUI
import Network
import Models
import Shimmer
import Status
import DesignSystem
import Env

public struct TimelineView: View {
  private enum Constants {
    static let scrollToTop = "top"
  }
  
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath
  
  @StateObject private var viewModel = TimelineViewModel()

  @State private var scrollProxy: ScrollViewProxy?
  @Binding var timeline: TimelineFilter
  @Binding var scrollToTopSignal: Int
  
  private let feedbackGenerator = UIImpactFeedbackGenerator()
  
  public init(timeline: Binding<TimelineFilter>, scrollToTopSignal: Binding<Int>) {
    _timeline = timeline
    _scrollToTopSignal = scrollToTopSignal
  }
  
  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .top) {
        ScrollView {
          Rectangle()
            .frame(height: 0)
            .id(Constants.scrollToTop)
          LazyVStack {
            tagHeaderView
              .padding(.bottom, 16)
            switch viewModel.timeline {
            case .remoteLocal:
              StatusesListView(fetcher: viewModel, isRemote: true)
            default:
              StatusesListView(fetcher: viewModel)
            }
          }
          .padding(.top, .layoutPadding + (!viewModel.pendingStatuses.isEmpty ? 28 : 0))
        }
        .background(theme.primaryBackgroundColor)
        if viewModel.pendingStatusesEnabled {
          makePendingNewPostsView(proxy: proxy)
        }
      }
      .onAppear {
        scrollProxy = proxy
      }
    }
    .navigationTitle(timeline.title())
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      if viewModel.client == nil {
        viewModel.client = client
        viewModel.timeline = timeline
      }
    }
    .refreshable {
      feedbackGenerator.impactOccurred(intensity: 0.3)
      await viewModel.fetchStatuses(userIntent: true)
      feedbackGenerator.impactOccurred(intensity: 0.7)
    }
    .onChange(of: watcher.latestEvent?.id) { _ in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent, currentAccount: account)
      }
    }
    .onChange(of: scrollToTopSignal, perform: { _ in
      withAnimation {
        scrollProxy?.scrollTo(Constants.scrollToTop, anchor: .top)
      }
    })
    .onChange(of: timeline) { newTimeline in
      switch newTimeline {
      case let .remoteLocal(server):
        viewModel.client = Client(server: server)
      default:
        viewModel.client = client
      }
      viewModel.timeline = newTimeline
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
      HStack(spacing: 6) {
        Button {
          withAnimation {
            proxy.scrollTo(Constants.scrollToTop)
            viewModel.displayPendingStatuses()
          }
        } label: {
          Text(viewModel.pendingStatusesButtonTitle)
        }
        .buttonStyle(.bordered)
        .background(.thinMaterial)
        .cornerRadius(8)
        if viewModel.pendingStatuses.count > 1 {
          Button {
            withAnimation {
              viewModel.dequeuePendingStatuses()
            }
          } label: {
            Image(systemName: "text.insert")
          }
          .buttonStyle(.bordered)
          .background(.thinMaterial)
          .cornerRadius(8)
        }
      }
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
              viewModel.tag = await account.unfollowTag(id: tag.name)
            } else {
              viewModel.tag = await account.followTag(id: tag.name)
            }
          }
        } label: {
          Text(tag.following ? "Following": "Follow")
        }.buttonStyle(.bordered)
      }
      .padding(.horizontal, .layoutPadding)
      .padding(.vertical, 8)
      .background(theme.secondaryBackgroundColor)
    }
  }
}
