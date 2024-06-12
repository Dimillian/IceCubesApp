import Charts
import DesignSystem
import Env
import Models
import Network
import StatusKit
import SwiftData
import SwiftUI
import SwiftUIIntrospect

@MainActor
public struct TimelineView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var account
  @Environment(StreamWatcher.self) private var watcher
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath

  @State private var viewModel = TimelineViewModel()
  @State private var prefetcher = TimelineMediaPrefetcher()
  @State private var contentFilter = TimelineContentFilter.shared

  @State private var wasBackgrounded: Bool = false
  @State private var collectionView: UICollectionView?

  @Binding var timeline: TimelineFilter
  @Binding var pinnedFilters: [TimelineFilter]
  @Binding var selectedTagGroup: TagGroup?
  @Binding var scrollToTopSignal: Int

  @Query(sort: \TagGroup.creationDate, order: .reverse) var tagGroups: [TagGroup]

  private let canFilterTimeline: Bool

  public init(timeline: Binding<TimelineFilter>,
              pinnedFilters: Binding<[TimelineFilter]>,
              selectedTagGroup: Binding<TagGroup?>,
              scrollToTopSignal: Binding<Int>,
              canFilterTimeline: Bool)
  {
    _timeline = timeline
    _pinnedFilters = pinnedFilters
    _selectedTagGroup = selectedTagGroup
    _scrollToTopSignal = scrollToTopSignal
    self.canFilterTimeline = canFilterTimeline
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .top) {
        List {
          scrollToTopView
          TimelineTagGroupheaderView(group: $selectedTagGroup, timeline: $timeline)
          TimelineTagHeaderView(tag: $viewModel.tag)
          switch viewModel.timeline {
          case .remoteLocal:
            StatusesListView(fetcher: viewModel, client: client, routerPath: routerPath, isRemote: true)
          default:
            StatusesListView(fetcher: viewModel, client: client, routerPath: routerPath)
              .environment(\.isHomeTimeline, timeline == .home)
          }
        }
        .id(client.id)
        .environment(\.defaultMinListRowHeight, 1)
        .listStyle(.plain)
        #if !os(visionOS)
          .scrollContentBackground(.hidden)
          .background(theme.primaryBackgroundColor)
        #endif
          .introspect(.list, on: .iOS(.v17, .v18)) { (collectionView: UICollectionView) in
            DispatchQueue.main.async {
              self.collectionView = collectionView
            }
            prefetcher.viewModel = viewModel
            collectionView.isPrefetchingEnabled = true
            collectionView.prefetchDataSource = prefetcher
          }
        if viewModel.timeline.supportNewestPagination {
          TimelineUnreadStatusesView(observer: viewModel.pendingStatusesObserver)
        }
      }
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
      .if(canFilterTimeline && !pinnedFilters.isEmpty) { view in
        view.toolbarBackground(.hidden, for: .navigationBar)
      }
      .onChange(of: viewModel.scrollToIndex) { _, newValue in
        if let collectionView,
           let newValue,
           let rows = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0),
           rows > newValue
        {
          collectionView.scrollToItem(at: .init(row: newValue, section: 0),
                                      at: .top,
                                      animated: viewModel.scrollToIndexAnimated)
          viewModel.scrollToIndexAnimated = false
          viewModel.scrollToIndex = nil
        }
      }
      .onChange(of: scrollToTopSignal) {
        withAnimation {
          proxy.scrollTo(ScrollToView.Constants.scrollToTop, anchor: .top)
        }
      }
    }
    .toolbar {
      toolbarTitleView
      toolbarTagGroupButton
    }
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      viewModel.canFilterTimeline = canFilterTimeline
      viewModel.isTimelineVisible = true

      if viewModel.client == nil {
        viewModel.client = client
      }

      viewModel.timeline = timeline
    }
    .onDisappear {
      viewModel.isTimelineVisible = false
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
      case let .list(list):
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
      switch newValue {
      case let .remoteLocal(server, _):
        viewModel.client = Client(server: server)
      default:
        switch oldValue {
        case let .remoteLocal(server, _):
          if newValue == .latest {
            viewModel.client = Client(server: server)
          } else {
            viewModel.client = client
          }
        default:
          viewModel.client = client
        }
      }
      viewModel.timeline = newValue
    }
    .onChange(of: viewModel.timeline) { _, newValue in
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

  @ToolbarContentBuilder
  private var toolbarTitleView: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      VStack(alignment: .center) {
        switch timeline {
        case let .remoteLocal(_, filter):
          Text(filter.localizedTitle())
            .font(.headline)
          Text(timeline.localizedTitle())
            .font(.caption)
            .foregroundStyle(.secondary)
        case .home:
          Text(timeline.localizedTitle())
            .font(.headline)
        default:
          Text(timeline.localizedTitle())
            .font(.headline)
        }
      }
      .accessibilityRepresentation {
        switch timeline {
        case let .remoteLocal(_, filter):
          if canFilterTimeline {
            Menu(filter.localizedTitle()) {}
          } else {
            Text(filter.localizedTitle())
          }
        default:
          if canFilterTimeline {
            Menu(timeline.localizedTitle()) {}
          } else {
            Text(timeline.localizedTitle())
          }
        }
      }
      .accessibilityAddTraits(.isHeader)
      .accessibilityRemoveTraits(.isButton)
      .accessibilityRespondsToUserInteraction(canFilterTimeline)
    }
  }

  @ToolbarContentBuilder
  private var toolbarTagGroupButton: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      switch timeline {
      case let .hashtag(tag, _):
        if !tagGroups.isEmpty {
          Menu {
            Section("tag-groups.edit.section.title") {
              ForEach(tagGroups) { group in
                Button {
                  if group.tags.contains(tag) {
                    group.tags.removeAll(where: { $0 == tag })
                  } else {
                    group.tags.append(tag)
                  }
                } label: {
                  Label(group.title,
                        systemImage: group.tags.contains(tag) ? "checkmark.rectangle.fill" : "checkmark.rectangle")
                }
              }
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      default:
        EmptyView()
      }
    }
  }

  private var scrollToTopView: some View {
    ScrollToView()
      .frame(height: pinnedFilters.isEmpty ? .layoutPadding : 0)
      .onAppear {
        viewModel.scrollToTopVisible = true
      }
      .onDisappear {
        viewModel.scrollToTopVisible = false
      }
  }
}
