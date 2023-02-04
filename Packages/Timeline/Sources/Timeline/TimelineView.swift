import DesignSystem
import Env
import Models
import Network
import Shimmer
import Status
import SwiftUI
import Introspect

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

  @State private var wasBackgrounded: Bool = false
  @State private var collectionView: UICollectionView?

  @Binding var timeline: TimelineFilter
  @Binding var scrollToTopSignal: Int

  public init(timeline: Binding<TimelineFilter>, scrollToTopSignal: Binding<Int>) {
    _timeline = timeline
    _scrollToTopSignal = scrollToTopSignal
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .top) {
        List {
          if viewModel.tag == nil {
            scrollToTopView
          } else {
            tagHeaderView
          }
          switch viewModel.timeline {
          case .remoteLocal:
            StatusesListView(fetcher: viewModel, isRemote: true)
          default:
            StatusesListView(fetcher: viewModel)
          }
        }
        .id(client.id)
        .environment(\.defaultMinListRowHeight, 1)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
        .introspect(selector: TargetViewSelector.ancestorOrSiblingContaining,
                    customize: { (collectionView: UICollectionView) in
          self.collectionView = collectionView
        })
        if viewModel.pendingStatusesEnabled {
          PendingStatusesObserverView(observer: viewModel.pendingStatusesObserver)
        }
      }
      .onChange(of: viewModel.scrollToIndex) { index in
        if let index {
          collectionView?.scrollToItem(at: .init(row: index, section: 0),
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
    .navigationTitle(timeline.localizedTitle())
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      if viewModel.client == nil {
        viewModel.client = client
        viewModel.timeline = timeline
      } else {
        Task {
          await viewModel.fetchStatuses()
        }
      }
    }
    .refreshable {
      HapticManager.shared.impact(intensity: 0.3)
      await viewModel.fetchStatuses()
      HapticManager.shared.impact(intensity: 0.7)
    }
    .onChange(of: watcher.latestEvent?.id) { _ in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent, currentAccount: account)
      }
    }
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
        if wasBackgrounded {
          wasBackgrounded = false
          Task {
            await viewModel.fetchStatuses()
          }
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
      VStack(alignment: .leading) {
        Spacer()
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("#\(tag.name)")
              .font(.scaledHeadline)
            Text("timeline.n-recent-from-n-participants \(tag.totalUses) \(tag.totalAccounts)")
              .font(.scaledFootnote)
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
            Text(tag.following ? "account.follow.following" : "account.follow.follow")
          }.buttonStyle(.bordered)
        }
        Spacer()
      }
      .listRowBackground(theme.secondaryBackgroundColor)
      .listRowSeparator(.hidden)
      .listRowInsets(.init(top: 8,
                           leading: .layoutPadding,
                           bottom: 8,
                           trailing: .layoutPadding))
    }
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
  }
}
