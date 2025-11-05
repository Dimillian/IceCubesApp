import Charts
import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftData
import SwiftUI

@MainActor
public struct TimelineView: View {
  @Environment(\.scenePhase) private var scenePhase

  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var account
  @Environment(StreamWatcher.self) private var watcher
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath

  @State private var viewModel = TimelineViewModel()
  @State private var contentFilter = TimelineContentFilter.shared

  @State private var scrollToIdAnimated: String? = nil

  @State private var wasBackgrounded: Bool = false

  @Binding var timeline: TimelineFilter
  @Binding var pinnedFilters: [TimelineFilter]
  @Binding var selectedTagGroup: TagGroup?

  private let canFilterTimeline: Bool

  private var toolbarBackgroundVisibility: SwiftUI.Visibility {
    if canFilterTimeline, !pinnedFilters.isEmpty {
      return .hidden
    }
    return .visible
  }

  public init(
    timeline: Binding<TimelineFilter>,
    pinnedFilters: Binding<[TimelineFilter]>,
    selectedTagGroup: Binding<TagGroup?>,
    canFilterTimeline: Bool
  ) {
    _timeline = timeline
    _pinnedFilters = pinnedFilters
    _selectedTagGroup = selectedTagGroup
    self.canFilterTimeline = canFilterTimeline
  }

  public var body: some View {
    if #available(iOS 26.0, *) {
      timelineView
        .safeAreaBar(edge: .top) {
          if canFilterTimeline, !pinnedFilters.isEmpty {
            TimelineQuickAccessPills(pinnedFilters: $pinnedFilters, timeline: $timeline)
              .padding(.horizontal, .layoutPadding)
          }
        }
    } else {
      timelineView
        .toolbarBackground(toolbarBackgroundVisibility, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
          if canFilterTimeline, !pinnedFilters.isEmpty {
            VStack(spacing: 0) {
              TimelineQuickAccessPills(pinnedFilters: $pinnedFilters, timeline: $timeline)
                .padding(.vertical, 8)
                .padding(.horizontal, .layoutPadding)
                .background(theme.primaryBackgroundColor.opacity(0.30))
                .background(Material.ultraThin)
              Divider()
            }
          }
        }
    }
  }

  private var timelineView: some View {
    ZStack(alignment: .top) {
      TimelineListView(
        viewModel: viewModel,
        timeline: $timeline,
        pinnedFilters: $pinnedFilters,
        selectedTagGroup: $selectedTagGroup,
        scrollToIdAnimated: $scrollToIdAnimated)
      if viewModel.timeline.supportNewestPagination {
        TimelineUnreadStatusesView(observer: viewModel.pendingStatusesObserver) { statusId in
          if let statusId {
            scrollToIdAnimated = statusId
          }
        }
      }
    }
    .toolbar {
      TimelineToolbarTitleView(timeline: $timeline, canFilterTimeline: canFilterTimeline)
      if #available(iOS 26.0, *) {
        ToolbarSpacer(placement: .topBarTrailing)
      }
      if viewModel.canStreamTimeline(timeline) {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            viewModel.isStreamingTimeline.toggle()
          } label: {
            Image(
              systemName: viewModel.isStreamingTimeline
                ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
          }
          .tint(theme.labelColor)
        }
      }
      TimelineToolbarTagGroupButton(timeline: $timeline)
    }
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      viewModel.canFilterTimeline = canFilterTimeline

      if viewModel.client == nil {
        switch timeline {
        case .remoteLocal(let server, _):
          viewModel.client = MastodonClient(server: server)
        default:
          viewModel.client = client
        }
      }

      viewModel.timeline = timeline
    }
    .onDisappear {
      viewModel.saveMarker()
    }
    .refreshable {
      SoundEffectManager.shared.playSound(.pull)
      HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
      await viewModel.pullToRefresh()
      HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
      SoundEffectManager.shared.playSound(.refresh)
    }
    .onChange(of: watcher.latestEvent?.id) {
      Task {
        if let latestEvent = watcher.latestEvent {
          await viewModel.handleEvent(event: latestEvent)
        }
      }
    }
    .onChange(of: account.lists) { _, lists in
      guard client.isAuth else { return }
      switch timeline {
      case .list(let list):
        if let accountList = lists.first(where: { $0.id == list.id }),
          list.id == accountList.id,
          accountList.title != list.title
        {
          timeline = .list(list: accountList)
        }
      default:
        break
      }
    }
    .onChange(of: timeline) { oldValue, newValue in
      guard oldValue != newValue else { return }
      switch newValue {
      case .remoteLocal(let server, _):
        viewModel.client = MastodonClient(server: server)
      default:
        switch oldValue {
        case .remoteLocal(let server, _):
          if newValue == .latest {
            viewModel.client = MastodonClient(server: server)
          } else {
            viewModel.client = client
          }
        default:
          viewModel.client = client
        }
      }
      viewModel.timeline = newValue
    }
    .onChange(of: viewModel.timeline) { oldValue, newValue in
      guard oldValue != newValue, timeline != newValue else { return }
      timeline = newValue
    }
    .onChange(of: contentFilter.showReplies) { _, _ in
      Task { await viewModel.refreshTimelineContentFilter() }
    }
    .onChange(of: contentFilter.showBoosts) { _, _ in
      Task { await viewModel.refreshTimelineContentFilter() }
    }
    .onChange(of: contentFilter.showThreads) { _, _ in
      Task { await viewModel.refreshTimelineContentFilter() }
    }
    .onChange(of: contentFilter.showQuotePosts) { _, _ in
      Task { await viewModel.refreshTimelineContentFilter() }
    }
    .onChange(of: scenePhase) { _, newValue in
      switch newValue {
      case .active:
        if wasBackgrounded {
          wasBackgrounded = false
          viewModel.refreshTimeline()
        }
      case .background:
        wasBackgrounded = true
        viewModel.saveMarker()

      default:
        break
      }
    }
  }
}
