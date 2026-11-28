import Models
import SwiftUI
import Testing

@testable import StatusKit

@MainActor
@Suite("Timeline gap scroll state")
struct TimelineGapScrollStateTests {
  private var gap: TimelineGap { TimelineGap(sinceId: "10", maxId: "100") }

  private func viewport(_ offset: CGFloat) -> TimelineGapScrollState.Viewport {
    .init(offset: offset, height: 800, insetTop: 100, insetBottom: 0)
  }

  private func scroll(_ state: TimelineGapScrollState, through offsets: [CGFloat]) {
    for offset in offsets {
      state.viewportChanged(viewport(offset), isAnimating: false)
    }
  }

  @Test
  func fallsBackToGapPositionWithoutScroll() async {
    let state = TimelineGapScrollState()
    state.viewportChanged(viewport(0), isAnimating: false)

    state.gapFrameChanged(id: gap.id, frame: CGRect(x: 0, y: 600, width: 300, height: 60))
    #expect(state.fillDirection(for: gap) == .fromNewer)

    state.gapFrameChanged(id: gap.id, frame: CGRect(x: 0, y: 150, width: 300, height: 60))
    #expect(state.fillDirection(for: gap) == .fromOlder)
  }

  @Test
  func scrollingUpFillsFromOlder() async {
    let state = TimelineGapScrollState()
    scroll(state, through: [1000, 990, 970, 950])
    #expect(state.lastScrollDirection == .towardNewer)
    #expect(state.fillDirection(for: gap) == .fromOlder)

    scroll(state, through: [960, 980, 1000])
    #expect(state.lastScrollDirection == .towardOlder)
    #expect(state.fillDirection(for: gap) == .fromNewer)
  }

  @Test
  func smallJitterDoesNotFlipDirection() async {
    let state = TimelineGapScrollState()
    scroll(state, through: [1000, 970])
    scroll(state, through: [975, 980])
    #expect(state.lastScrollDirection == .towardNewer)
  }

  @Test
  func jumpsAndAnimatedScrollsAreIgnored() async {
    let state = TimelineGapScrollState()
    scroll(state, through: [5000, 1000])  // programmatic jump
    #expect(state.lastScrollDirection == nil)

    state.viewportChanged(viewport(900), isAnimating: true)
    state.viewportChanged(viewport(800), isAnimating: true)
    #expect(state.lastScrollDirection == nil)

    state.willScrollProgrammatically()
    scroll(state, through: [850, 900])
    #expect(state.lastScrollDirection == nil)
  }

  @Test
  func openEndedGapAlwaysFillsFromNewer() async {
    let state = TimelineGapScrollState()
    scroll(state, through: [1000, 950])
    #expect(state.fillDirection(for: TimelineGap(sinceId: nil, maxId: "9")) == .fromNewer)
  }

  @Test
  func anchorPlacementKeepsRowTopInPlace() async throws {
    let state = TimelineGapScrollState()
    state.viewportChanged(viewport(0), isAnimating: false)
    // Row top 300pt into the 700pt visible area, 200pt tall.
    state.anchorFrameChanged(id: "10", frame: CGRect(x: 0, y: 400, width: 300, height: 200))

    #expect(state.consumeAnchorPlacement(for: "10") == nil, "Only a pending fill anchor is used")

    state.beginFill(anchorId: "10")
    #expect(state.consumeAnchorPlacement(for: "other") == nil)
    state.beginFill(anchorId: "10")
    let placement = try #require(state.consumeAnchorPlacement(for: "10"))
    #expect(placement.visibleTop == 300)
    // top + y * rowHeight == y * visibleHeight
    let y = placement.unitPoint.y
    #expect(abs((300 + y * 200) - y * 700) < 0.001)
    #expect(state.consumeAnchorPlacement(for: "10") == nil, "Consumed once")
  }

  @Test
  func anchorPlacementForRowTallerThanFreeSpace() async throws {
    let state = TimelineGapScrollState()
    state.viewportChanged(viewport(0), isAnimating: false)
    // Row top 600pt into the 700pt visible area, 500pt tall: it doesn't fit.
    state.anchorFrameChanged(id: "10", frame: CGRect(x: 0, y: 700, width: 300, height: 500))
    state.beginFill(anchorId: "10")

    let placement = try #require(state.consumeAnchorPlacement(for: "10"))
    #expect(placement.visibleTop == 600)
    #expect(placement.unitPoint.y == 1)
  }
}
