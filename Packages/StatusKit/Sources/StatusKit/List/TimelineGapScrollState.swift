import Models
import SwiftUI

/// Scroll context a timeline list shares with its gap rows, so "Load more" can fill a gap
/// from the end next to where the user is reading, and keep the row under the gap in place.
///
/// Inject it with `.environment(_:)` on the `List` and call `trackGapScrolling(_:)` on it.
@MainActor
@Observable
public final class TimelineGapScrollState {
  public enum ScrollDirection: Sendable {
    /// Content offset decreasing: the user moves up toward newer posts.
    case towardNewer
    /// Content offset increasing: the user moves down toward older posts.
    case towardOlder
  }

  /// Last direction the user scrolled in, `nil` until they scroll.
  public private(set) var lastScrollDirection: ScrollDirection?
  /// Gaps whose center sits in the upper half of the viewport.
  private var gapsInUpperHalf: Set<String> = []

  @ObservationIgnored private var viewport = Viewport()
  @ObservationIgnored private var lastOffset: CGFloat?
  @ObservationIgnored private var travel: CGFloat = 0
  @ObservationIgnored private var anchorFrames: [String: CGRect] = [:]
  @ObservationIgnored private var pendingAnchorId: String?
  @ObservationIgnored private var ignoreScrollUntil: Date = .distantPast

  /// Distance the user has to scroll in one direction before it counts.
  private static let directionThreshold: CGFloat = 24

  struct Viewport: Equatable {
    var offset: CGFloat = 0
    var height: CGFloat = 0
    var insetTop: CGFloat = 0
    var insetBottom: CGFloat = 0

    var visibleHeight: CGFloat { height - insetTop - insetBottom }
  }

  public init() {}

  // MARK: - Direction

  /// Which end of `gap` the next tap should fill.
  ///
  /// The last scroll direction wins. Without one (e.g. right after launch), the gap's position
  /// decides: a gap in the upper half of the viewport means the reader is below it.
  public func fillDirection(for gap: TimelineGap) -> GapFillDirection {
    guard !gap.isOpenEnded else { return .fromNewer }
    switch lastScrollDirection {
    case .towardNewer:
      return .fromOlder
    case .towardOlder:
      return .fromNewer
    case nil:
      return gapsInUpperHalf.contains(gap.id) ? .fromOlder : .fromNewer
    }
  }

  func viewportChanged(_ new: Viewport, isAnimating: Bool) {
    defer {
      viewport = new
      lastOffset = new.offset
    }
    guard let lastOffset, new.height > 0 else { return }
    let delta = new.offset - lastOffset
    // Skip programmatic jumps (scrollTo restoring position), animated scrolls (scroll to top)
    // and the rubber band above the first row (pull to refresh).
    guard !isAnimating,
      Date.now >= ignoreScrollUntil,
      abs(delta) < new.visibleHeight * 0.75,
      new.offset > -new.insetTop
    else {
      travel = 0
      return
    }
    if delta.sign != travel.sign { travel = 0 }
    travel += delta
    if travel <= -Self.directionThreshold, lastScrollDirection != .towardNewer {
      lastScrollDirection = .towardNewer
    } else if travel >= Self.directionThreshold, lastScrollDirection != .towardOlder {
      lastScrollDirection = .towardOlder
    }
  }

  /// Call right before a programmatic `scrollTo`, so the jump isn't taken for a user scroll.
  public func willScrollProgrammatically() {
    ignoreScrollUntil = .now.addingTimeInterval(0.4)
    travel = 0
  }

  // MARK: - Geometry reported by rows

  /// `frame` is in the `.scrollView` coordinate space.
  func gapFrameChanged(id: String, frame: CGRect) {
    guard viewport.height > 0 else { return }
    let isUpper = frame.midY < viewport.insetTop + viewport.visibleHeight / 2
    if isUpper != gapsInUpperHalf.contains(id) {
      if isUpper {
        gapsInUpperHalf.insert(id)
      } else {
        gapsInUpperHalf.remove(id)
      }
    }
  }

  func gapDisappeared(id: String) {
    gapsInUpperHalf.remove(id)
  }

  /// Frame of the row directly below a gap, in the `.scrollView` coordinate space.
  func anchorFrameChanged(id: String, frame: CGRect) {
    anchorFrames[id] = frame
  }

  func anchorDisappeared(id: String) {
    anchorFrames[id] = nil
  }

  // MARK: - Keeping the anchor in place

  /// Call when a `.fromOlder` fill starts. `anchorId` is the row directly below the gap.
  func beginFill(anchorId: String?) {
    pendingAnchorId = anchorId
  }

  /// Where the row under a filled gap has to go so it doesn't move on screen.
  public struct AnchorPlacement: Equatable, Sendable {
    /// Distance from the top of the visible area (below the top inset) to the row's top.
    public let visibleTop: CGFloat
    /// Fallback for `ScrollViewProxy.scrollTo(_:anchor:)` when the offset can't be set directly.
    /// `scrollTo` aligns the row's point at `y` with the viewport's point at `y`; solving
    /// `top + y * rowHeight == y * viewportHeight` keeps the row's top in place. Only exact
    /// while the row fits on screen.
    public let unitPoint: UnitPoint
  }

  /// The placement for the row with `id`, or `nil` if `id` isn't the pending fill anchor.
  /// Consumed on read.
  public func consumeAnchorPlacement(for id: String) -> AnchorPlacement? {
    guard pendingAnchorId == id else { return nil }
    pendingAnchorId = nil
    guard let frame = anchorFrames[id] else { return nil }
    let top = frame.minY - viewport.insetTop
    let free = viewport.visibleHeight - frame.height
    let unitPoint = free > 1 ? UnitPoint(x: 0.5, y: min(max(top / free, 0), 1)) : .top
    return AnchorPlacement(visibleTop: top, unitPoint: unitPoint)
  }
}

// MARK: - List modifier

extension View {
  /// Feeds the list's scroll offset into `state`. Place it on the timeline `List`.
  public func trackGapScrolling(_ state: TimelineGapScrollState) -> some View {
    modifier(TrackGapScrollingModifier(state: state))
  }
}

private struct TrackGapScrollingModifier: ViewModifier {
  let state: TimelineGapScrollState
  @State private var isAnimating = false

  func body(content: Content) -> some View {
    if #available(iOS 18, visionOS 2, *) {
      content
        .onScrollPhaseChange { _, phase in
          isAnimating = phase == .animating
        }
        .onScrollGeometryChange(for: TimelineGapScrollState.Viewport.self) { geometry in
          .init(
            offset: geometry.contentOffset.y,
            height: geometry.containerSize.height,
            insetTop: geometry.contentInsets.top,
            insetBottom: geometry.contentInsets.bottom)
        } action: { _, new in
          state.viewportChanged(new, isAnimating: isAnimating)
        }
    } else {
      content
    }
  }
}
