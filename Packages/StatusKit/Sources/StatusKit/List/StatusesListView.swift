import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct StatusesListView<Fetcher>: View where Fetcher: StatusesFetcher {
  @Environment(Theme.self) private var theme
  @Environment(TimelineGapScrollState.self) private var gapScrollState: TimelineGapScrollState?

  @State private var fetcher: Fetcher
  // Whether this status is on a remote local timeline (many actions are unavailable if so)
  private let isRemote: Bool
  private let routerPath: RouterPath
  private let client: MastodonClient
  private let filterContext: Filter.Context?

  public init(
    fetcher: Fetcher,
    client: MastodonClient,
    routerPath: RouterPath,
    isRemote: Bool = false,
    filterContext: Filter.Context? = nil
  ) {
    _fetcher = .init(initialValue: fetcher)
    self.isRemote = isRemote
    self.client = client
    self.routerPath = routerPath
    self.filterContext = filterContext
  }

  public var body: some View {
    switch fetcher.statusesState {
    case .loading:
      ForEach(Status.placeholders()) { status in
        StatusRowView(
          viewModel: .init(
            status: status,
            client: client,
            routerPath: routerPath,
            filterContext: filterContext),
          context: .timeline
        )
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
      }
    case .error:
      ErrorView(
        title: "status.error.title",
        message: "status.error.loading.message",
        buttonTitle: "action.retry"
      ) {
        await fetcher.fetchNewestStatuses(pullToRefresh: false)
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)

    case .display(let statuses, let nextPageState):
      ForEach(statuses) { status in
        StatusRowView(
          viewModel: StatusRowViewModel(
            status: status,
            client: client,
            routerPath: routerPath,
            isRemote: isRemote,
            filterContext: filterContext),
          context: .timeline
        )
        .onAppear {
          fetcher.statusDidAppear(status: status)
        }
        .onDisappear {
          fetcher.statusDidDisappear(status: status)
        }
      }
      makeNextPageRow(nextPageState: nextPageState)

    case .displayWithGaps(let items, let nextPageState):
      let rowsBelowGaps = Self.rowIdsBelowGaps(in: items)
      ForEach(items) { item in
        ZStack {
          switch item {
          case .status(let status):
            StatusRowView(
              viewModel: StatusRowViewModel(
                status: status,
                client: client,
                routerPath: routerPath,
                isRemote: isRemote,
                filterContext: filterContext),
              context: .timeline
            )
            .onAppear {
              fetcher.statusDidAppear(status: status)
            }
            .onDisappear {
              fetcher.statusDidDisappear(status: status)
            }
            .background {
              if let gapScrollState, rowsBelowGaps.contains(status.id) {
                GapAnchorGeometryReader(id: status.id, state: gapScrollState)
              }
            }

          case .gap(let gap):
            ZStack {
              if let gapLoader = fetcher as? GapLoadingFetcher {
                let direction = gapScrollState?.fillDirection(for: gap) ?? .fromNewer
                TimelineGapView(gap: gap, direction: direction) {
                  if direction == .fromOlder {
                    gapScrollState?.beginFill(anchorId: Self.rowIdBelow(gapId: gap.id, in: items))
                  }
                  await gapLoader.loadGap(gap: gap, direction: direction)
                }
                .background {
                  if let gapScrollState {
                    GapGeometryReader(id: gap.id, state: gapScrollState)
                  }
                }
              }
            }
          }
        }
        #if os(visionOS)
          .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background).hoverEffect()
          )
          .listRowHoverEffectDisabled()
        #else
          .listRowBackground(makeBackgroundColorFor(status: item.status))
        #endif
        .listRowInsets(
          .init(
            top: 0,
            leading: .layoutPadding,
            bottom: 0,
            trailing: .layoutPadding)
        )
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
          return -100
        }
        .alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
          return viewDimensions.width + 100
        }
      }
      makeNextPageRow(nextPageState: nextPageState)
    }
  }

  /// Ids of the first status row under each gap.
  private static func rowIdsBelowGaps(in items: [TimelineItem]) -> Set<String> {
    var ids: Set<String> = []
    for (item, next) in zip(items, items.dropFirst()) {
      if case .gap = item, case .status(let status) = next {
        ids.insert(status.id)
      }
    }
    return ids
  }

  private static func rowIdBelow(gapId: String, in items: [TimelineItem]) -> String? {
    guard let index = items.firstIndex(where: { $0.id == gapId }) else { return nil }
    return items[(index + 1)...].lazy.compactMap(\.status).first?.id
  }

  @ViewBuilder
  private func makeNextPageRow(nextPageState: StatusesState.PagingState) -> some View {
    ZStack {
      switch nextPageState {
      case .hasNextPage:
        NextPageView {
          try await fetcher.fetchNextPage()
        }
        .padding(.horizontal, .layoutPadding)

      case .none:
        EmptyView()
      }
    }
    .listRowSeparator(.hidden, edges: .all)
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
    .alignmentGuide(.listRowSeparatorLeading) { _ in
      -100
    }
  }

  @ViewBuilder
  private func makeBackgroundColorFor(status: Status?) -> some View {
    if let status {
      if status.visibility == .direct {
        theme.tintColor.opacity(0.15)
      } else if status.mentions.first(where: { $0.id == CurrentAccount.shared.account?.id }) != nil
      {
        theme.secondaryBackgroundColor
      } else {
        theme.primaryBackgroundColor
      }
    } else {
      theme.primaryBackgroundColor
    }
  }
}

/// Reports the frame of a gap row to the scroll state.
private struct GapGeometryReader: View {
  let id: String
  let state: TimelineGapScrollState

  var body: some View {
    Color.clear
      .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { frame in
        state.gapFrameChanged(id: id, frame: frame)
      }
      .onDisappear {
        state.gapDisappeared(id: id)
      }
  }
}

/// Reports the frame of the row under a gap, the one to keep in place on a `.fromOlder` fill.
private struct GapAnchorGeometryReader: View {
  let id: String
  let state: TimelineGapScrollState

  var body: some View {
    Color.clear
      .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { frame in
        state.anchorFrameChanged(id: id, frame: frame)
      }
  }
}
