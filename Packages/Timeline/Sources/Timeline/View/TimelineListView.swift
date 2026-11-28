import Charts
import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftData
import SwiftUI
import SwiftUIIntrospect
import UIKit

@MainActor
struct TimelineListView: View {
  @Environment(\.selectedTabScrollToTop) private var selectedTabScrollToTop

  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme

  var viewModel: TimelineViewModel
  @Binding var timeline: TimelineFilter
  @Binding var pinnedFilters: [TimelineFilter]
  @Binding var selectedTagGroup: TagGroup?
  @Binding var scrollToIdAnimated: String?

  @State private var gapScrollState = TimelineGapScrollState()
  @State private var listScrollView = WeakScrollView()

  var body: some View {
    @Bindable var viewModel = viewModel
    ScrollViewReader { proxy in
      List {
        ScrollToView()
          .frame(height: pinnedFilters.isEmpty ? .layoutPadding : 0)
          .onAppear {
            viewModel.scrollToTopVisible = true
          }
          .onDisappear {
            viewModel.scrollToTopVisible = false
          }
        TimelineTagGroupheaderView(group: $selectedTagGroup, timeline: $timeline)
        TimelineTagHeaderView(tag: $viewModel.tag)
        switch viewModel.timeline {
        case .remoteLocal:
          StatusesListView(
            fetcher: viewModel,
            client: client,
            routerPath: routerPath,
            isRemote: true,
            filterContext: timeline.filterContext)
        default:
          StatusesListView(
            fetcher: viewModel,
            client: client,
            routerPath: routerPath,
            filterContext: timeline.filterContext)
            .environment(\.isHomeTimeline, timeline == .home)
        }
      }
      .id(client.id)
      .environment(gapScrollState)
      .trackGapScrolling(gapScrollState)
      .introspect(.list, on: .iOS(.v18, .v26), .visionOS(.v1, .v2, .v26)) { collectionView in
        listScrollView.view = collectionView
      }
      .environment(\.defaultMinListRowHeight, 1)
      .listStyle(.plain)
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
      #endif
      .onChange(of: viewModel.scrollToId) { _, newValue in
        if let newValue {
          gapScrollState.willScrollProgrammatically()
          if let placement = gapScrollState.consumeAnchorPlacement(for: newValue) {
            // After a gap fill from older posts, put the row under the gap back where it was.
            restore(newValue, to: placement, proxy: proxy)
          } else {
            proxy.scrollTo(newValue, anchor: .top)
          }
          viewModel.scrollToId = nil
        }
      }
      .onChange(of: scrollToIdAnimated) { _, newValue in
        if let newValue {
          withAnimation {
            proxy.scrollTo(newValue, anchor: .top)
            scrollToIdAnimated = nil
          }
        }
      }
      .onChange(of: selectedTabScrollToTop) { _, newValue in
        if newValue == 0, routerPath.path.isEmpty {
          withAnimation {
            proxy.scrollTo(ScrollToView.Constants.scrollToTop, anchor: .top)
          }
        }
      }
    }
  }

  /// Scrolls the row to the top edge, then moves it down to `placement.visibleTop`, so it ends up
  /// exactly where it was regardless of its height. Falls back to a `UnitPoint` anchor when the
  /// list's scroll view isn't available.
  private func restore(
    _ id: String,
    to placement: TimelineGapScrollState.AnchorPlacement,
    proxy: ScrollViewProxy
  ) {
    guard let scrollView = listScrollView.view else {
      proxy.scrollTo(id, anchor: placement.unitPoint)
      return
    }
    proxy.scrollTo(id, anchor: .top)
    // Let SwiftUI apply the new rows and the scroll before adjusting.
    DispatchQueue.main.async {
      scrollView.layoutIfNeeded()
      let minOffset = -scrollView.adjustedContentInset.top
      let maxOffset = max(
        minOffset,
        scrollView.contentSize.height - scrollView.bounds.height
          + scrollView.adjustedContentInset.bottom)
      let target = scrollView.contentOffset.y - placement.visibleTop
      gapScrollState.willScrollProgrammatically()
      scrollView.setContentOffset(
        CGPoint(x: scrollView.contentOffset.x, y: min(max(target, minOffset), maxOffset)),
        animated: false)
    }
  }
}

/// Holds the list's scroll view without keeping it alive.
@MainActor
private final class WeakScrollView {
  weak var view: UIScrollView?
}
