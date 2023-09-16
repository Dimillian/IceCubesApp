import DesignSystem
import Env
import Models
import Network
import Shimmer
import Status
import SwiftUI
import SwiftUIIntrospect

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
  @StateObject private var prefetcher = TimelinePrefetcher()

  @State private var wasBackgrounded: Bool = false
  @State private var collectionView: UICollectionView?

  @Binding var timeline: TimelineFilter
  @Binding var scrollToTopSignal: Int
  private let canFilterTimeline: Bool

  public init(timeline: Binding<TimelineFilter>, scrollToTopSignal: Binding<Int>, canFilterTimeline: Bool) {
    _timeline = timeline
    _scrollToTopSignal = scrollToTopSignal
    self.canFilterTimeline = canFilterTimeline
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .top) {
        List {
          if viewModel.tagGroup != nil {
            tagGroupHeaderView
          } else if viewModel.tag == nil {
            scrollToTopView
          } else {
            tagHeaderView
          }
          switch viewModel.timeline {
          case .remoteLocal:
            StatusesListView(fetcher: viewModel, client: client, routerPath: routerPath, isRemote: true)
          default:
            StatusesListView(fetcher: viewModel, client: client, routerPath: routerPath)
          }
        }
        .id(client.id)
        .environment(\.defaultMinListRowHeight, 1)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
        .introspect(.list, on: .iOS(.v16, .v17)) { (collectionView: UICollectionView) in
          DispatchQueue.main.async {
            self.collectionView = collectionView
          }
          prefetcher.viewModel = viewModel
          collectionView.isPrefetchingEnabled = true
          collectionView.prefetchDataSource = prefetcher
        }
        if viewModel.timeline.supportNewestPagination {
          PendingStatusesObserverView(observer: viewModel.pendingStatusesObserver)
        }
      }
      .onChange(of: viewModel.scrollToIndex) { index in
        if let collectionView,
           let index,
           let rows = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0),
           rows > index
        {
          collectionView.scrollToItem(at: .init(row: index, section: 0),
                                      at: .top,
                                      animated: viewModel.scrollToIndexAnimated)
          viewModel.scrollToIndexAnimated = false
          viewModel.scrollToIndex = nil
        }
      }
      .onChange(of: scrollToTopSignal, perform: { _ in
        withAnimation {
          proxy.scrollTo(Constants.scrollToTop, anchor: .top)
        }
      })
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(alignment: .center) {
          switch timeline {
          case let .remoteLocal(_, filter):
            Text(filter.localizedTitle())
              .font(.headline)
            Text(timeline.localizedTitle())
              .font(.caption)
              .foregroundColor(.gray)
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
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      viewModel.isTimelineVisible = true

      if viewModel.client == nil {
        viewModel.client = client
      }

      viewModel.timeline = timeline
    }
    .onDisappear {
      viewModel.isTimelineVisible = false
    }
    .refreshable {
      SoundEffectManager.shared.playSound(of: .pull)
      HapticManager.shared.fireHaptic(of: .dataRefresh(intensity: 0.3))
      await viewModel.pullToRefresh()
      HapticManager.shared.fireHaptic(of: .dataRefresh(intensity: 0.7))
      SoundEffectManager.shared.playSound(of: .refresh)
    }
    .onChange(of: watcher.latestEvent?.id) { _ in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent, currentAccount: account)
      }
    }
    .onChange(of: timeline) { newTimeline in
      switch newTimeline {
      case let .remoteLocal(server, _):
        viewModel.client = Client(server: server)
      default:
        viewModel.client = client
      }
      viewModel.timeline = newTimeline
    }
    .onChange(of: viewModel.timeline, perform: { newValue in
      timeline = newValue
    })
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .active:
        if wasBackgrounded {
          wasBackgrounded = false
          viewModel.refreshTimeline()
        }
      case .background:
        wasBackgrounded = true

      default:
        break
      }
    })
  }

  @ViewBuilder
  private var tagHeaderView: some View {
    if let tag = viewModel.tag {
      headerView {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("#\(tag.name)")
              .font(.scaledHeadline)
            Text("timeline.n-recent-from-n-participants \(tag.totalUses) \(tag.totalAccounts)")
              .font(.scaledFootnote)
              .foregroundColor(.gray)
          }
          .accessibilityElement(children: .combine)
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
            Text(tag.following ? "account.follow.following" : "account.follow.follow")
          }.buttonStyle(.bordered)
        }
      }
    }
  }

  @ViewBuilder
  private var tagGroupHeaderView: some View {
    if let group = viewModel.tagGroup {
      headerView {
        HStack {
          ScrollView(.horizontal) {
            HStack(spacing: 4) {
              ForEach(group.tags, id: \.self) { tag in
                Button {
                  routerPath.navigate(to: .hashTag(tag: tag, account: nil))
                } label: {
                  Text("#\(tag)")
                    .font(.scaledHeadline)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .scrollIndicators(.hidden)
          Button("status.action.edit") {
            routerPath.presentedSheet = .editTagGroup(tagGroup: group, onSaved: { group in
              viewModel.timeline = .tagGroup(group)
            })
          }
          .buttonStyle(.bordered)
        }
      }
    }
  }

  @ViewBuilder
  private func headerView(
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading) {
      Spacer()
      content()
      Spacer()
    }
    .listRowBackground(theme.secondaryBackgroundColor)
    .listRowSeparator(.hidden)
    .listRowInsets(.init(top: 8,
                         leading: .layoutPadding,
                         bottom: 8,
                         trailing: .layoutPadding))
  }

  private var scrollToTopView: some View {
    HStack { EmptyView() }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)
      .listRowInsets(.init())
      .frame(height: .layoutPadding)
      .id(Constants.scrollToTop)
      .onAppear {
        viewModel.scrollToTopVisible = true
      }
      .onDisappear {
        viewModel.scrollToTopVisible = false
      }
      .accessibilityHidden(true)
  }
}
